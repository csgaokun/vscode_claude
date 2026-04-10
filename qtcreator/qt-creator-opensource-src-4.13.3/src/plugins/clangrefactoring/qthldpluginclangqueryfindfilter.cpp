/****************************************************************************
**
** Copyright (C) 2016 The Qt Company Ltd.
** Contact: https://www.qt.io/licensing/
**
** This file is part of Qt Hldplugin.
**
** Commercial License Usage
** Licensees holding valid commercial Qt licenses may use this file in
** accordance with the commercial license agreement provided with the
** Software or, alternatively, in accordance with the terms contained in
** a written agreement between you and The Qt Company. For licensing terms
** and conditions see https://www.qt.io/terms-conditions. For further
** information use the contact form at https://www.qt.io/contact-us.
**
** GNU General Public License Usage
** Alternatively, this file may be used under the terms of the GNU
** General Public License version 3 as published by the Free Software
** Foundation with exceptions as appearing in the file LICENSE.GPL3-EXCEPT
** included in the packaging of this file. Please review the following
** information to ensure the GNU General Public License requirements will
** be met: https://www.gnu.org/licenses/gpl-3.0.html.
**
****************************************************************************/

#include "qthldpluginclangqueryfindfilter.h"

#include "clangqueryprojectsfindfilterwidget.h"
#include "refactoringclient.h"

#include <cpptools/abstracteditorsupport.h>
#include <cpptools/cppmodelmanager.h>
#include <cpptools/projectinfo.h>

#include <projectexplorer/session.h>

#include <utils/smallstring.h>

namespace ClangRefactoring {

QtHldpluginClangQueryFindFilter::QtHldpluginClangQueryFindFilter(ClangBackEnd::RefactoringServerInterface &server,
                                                             SearchInterface &searchInterface,
                                                             RefactoringClient &refactoringClient)
    : ClangQueryProjectsFindFilter(server, searchInterface, refactoringClient)
{
}

void QtHldpluginClangQueryFindFilter::findAll(const QString &queryText, Core::FindFlags findFlags)
{
    prepareFind();

    ClangQueryProjectsFindFilter::findAll(queryText, findFlags);
}

void QtHldpluginClangQueryFindFilter::handleQueryOrExampleTextChanged()
{
    const QString queryText = this->queryText();
    const QString queryExampleText = this->queryExampleText();
    if (!queryText.isEmpty() && !queryExampleText.isEmpty())
        requestSourceRangesAndDiagnostics(queryText, queryExampleText);
}

QWidget *QtHldpluginClangQueryFindFilter::createConfigWidget()
{
    m_widget = new ClangQueryProjectsFindFilterWidget;

    refactoringClient().setClangQueryExampleHighlighter(m_widget->clangQueryExampleHighlighter());
    refactoringClient().setClangQueryHighlighter(m_widget->clangQueryHighlighter());

    QObject::connect(m_widget->queryExampleTextEdit(),
                     &QPlainTextEdit::textChanged,
                     this,
                     &QtHldpluginClangQueryFindFilter::handleQueryOrExampleTextChanged);

    QObject::connect(m_widget->queryTextEdit(),
                     &QPlainTextEdit::textChanged,
                     this,
                     &QtHldpluginClangQueryFindFilter::handleQueryOrExampleTextChanged);

    return m_widget;
}

bool ClangRefactoring::QtHldpluginClangQueryFindFilter::isValid() const
{
    return true;
}

QWidget *QtHldpluginClangQueryFindFilter::widget() const
{
    return m_widget;
}

QString QtHldpluginClangQueryFindFilter::queryText() const
{
    return m_widget->queryTextEdit()->toPlainText();
}

QString QtHldpluginClangQueryFindFilter::queryExampleText() const
{
    return m_widget->queryExampleTextEdit()->toPlainText();
}

namespace {

std::vector<ClangBackEnd::V2::FileContainer> createUnsavedContents()
{
    auto abstractEditors = CppTools::CppModelManager::instance()->abstractEditorSupports();
    std::vector<ClangBackEnd::V2::FileContainer> unsavedContents;
    unsavedContents.reserve(std::size_t(abstractEditors.size()));

    auto toFileContainer = [](const CppTools::AbstractEditorSupport *abstractEditor) {
        return ClangBackEnd::V2::FileContainer(ClangBackEnd::FilePath(abstractEditor->fileName()),
                                               -1,
                                               Utils::SmallString::fromQByteArray(
                                                   abstractEditor->contents()),
                                               {});
    };

    std::transform(abstractEditors.begin(),
                   abstractEditors.end(),
                   std::back_inserter(unsavedContents),
                   toFileContainer);

    return unsavedContents;
}

}

void QtHldpluginClangQueryFindFilter::prepareFind()
{
   ProjectExplorer::Project *currentProject = ProjectExplorer::SessionManager::startupProject();

    const CppTools::ProjectInfo projectInfo = CppTools::CppModelManager::instance()->projectInfo(currentProject);

    const QVector<CppTools::ProjectPart::Ptr> parts = projectInfo.projectParts();
    setProjectParts({parts.begin(), parts.end()});

    setUnsavedContent(createUnsavedContents());
}

} // namespace ClangRefactoring
