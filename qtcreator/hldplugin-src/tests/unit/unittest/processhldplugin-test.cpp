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

#include "googletest.h"

#include "eventspy.h"

#include <processhldplugin.h>
#include <processexception.h>
#include <processstartedevent.h>

#include <utils/hostosinfo.h>

#include <QProcess>

#include <future>

using testing::NotNull;

using ClangBackEnd::ProcessHldplugin;
using ClangBackEnd::ProcessException;
using ClangBackEnd::ProcessStartedEvent;

namespace  {

class ProcessHldplugin : public testing::Test
{
protected:
    void SetUp();

protected:
    ::ProcessHldplugin processHldplugin;
    QStringList m_arguments = {QStringLiteral("connectionName")};
};

TEST_F(ProcessHldplugin, ProcessIsNotNull)
{
    auto future = processHldplugin.createProcess();
    auto process = future.get();

    ASSERT_THAT(process.get(), NotNull());
}

TEST_F(ProcessHldplugin, ProcessIsRunning)
{
    auto future = processHldplugin.createProcess();
    auto process = future.get();

    ASSERT_THAT(process->state(), QProcess::Running);
}

TEST_F(ProcessHldplugin, ProcessPathIsNotExisting)
{
    processHldplugin.setProcessPath(Utils::HostOsInfo::withExecutableSuffix(ECHOSERVER"fail"));

    auto future = processHldplugin.createProcess();
    ASSERT_THROW(future.get(), ProcessException);
}

TEST_F(ProcessHldplugin, ProcessStartIsSucessfull)
{
    auto future = processHldplugin.createProcess();
    ASSERT_NO_THROW(future.get());
}

TEST_F(ProcessHldplugin, ProcessObserverGetsEvent)
{
    EventSpy eventSpy(ProcessStartedEvent::ProcessStarted);
    processHldplugin.setObserver(&eventSpy);
    auto future = processHldplugin.createProcess();

    eventSpy.waitForEvent();
}

TEST_F(ProcessHldplugin, TemporayPathIsSetForDefaultInitialization)
{
    QString path = processHldplugin.temporaryDirectory().path();

    ASSERT_THAT(path.size(), Gt(0));
}

TEST_F(ProcessHldplugin, TemporayPathIsResetted)
{
    std::string oldPath = processHldplugin.temporaryDirectory().path().toStdString();

    processHldplugin.resetTemporaryDirectory();

    ASSERT_THAT(processHldplugin.temporaryDirectory().path().toStdString(),
                AllOf(Not(IsEmpty()), Ne(oldPath)));
}

void ProcessHldplugin::SetUp()
{
    processHldplugin.setTemporaryDirectoryPattern("process-XXXXXXX");
    processHldplugin.resetTemporaryDirectory();
    processHldplugin.setProcessPath(Utils::HostOsInfo::withExecutableSuffix(ECHOSERVER));
    processHldplugin.setArguments(m_arguments);
}
}
