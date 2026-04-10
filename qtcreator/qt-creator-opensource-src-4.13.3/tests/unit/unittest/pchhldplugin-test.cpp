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

#include "fakeprocess.h"
#include "filesystem-utilities.h"
#include "testenvironment.h"

#include "mockbuilddependenciesstorage.h"
#include "mockclangpathwatcher.h"
#include "mockpchmanagerclient.h"
#include "testenvironment.h"

#include <filepathcaching.h>
#include <generatedfiles.h>
#include <pchhldplugin.h>
#include <precompiledheadersupdatedmessage.h>
#include <progressmessage.h>
#include <refactoringdatabaseinitializer.h>
#include <updateprojectpartsmessage.h>

#include <sqlitedatabase.h>

#include <QFileInfo>

namespace {

using ClangBackEnd::FilePath;
using ClangBackEnd::FilePathId;
using ClangBackEnd::FilePathIds;
using ClangBackEnd::FilePathView;
using ClangBackEnd::GeneratedFiles;
using ClangBackEnd::IdPaths;
using ClangBackEnd::IncludeSearchPathType;
using ClangBackEnd::PchTask;
using ClangBackEnd::PrecompiledHeadersUpdatedMessage;
using ClangBackEnd::ProjectChunkId;
using ClangBackEnd::ProjectPartContainer;
using ClangBackEnd::ProjectPartPch;
using ClangBackEnd::SourceEntries;
using ClangBackEnd::SourceEntry;
using ClangBackEnd::SourceType;
using ClangBackEnd::V2::FileContainer;

using Utils::PathString;
using Utils::SmallString;

using UnitTests::EndsWith;

MATCHER_P2(HasIdAndType,
           sourceId,
           sourceType,
           std::string(negation ? "hasn't" : "has")
               + PrintToString(ClangBackEnd::SourceEntry(sourceId, sourceType, -1)))
{
    const ClangBackEnd::SourceEntry &entry = arg;
    return entry.sourceId == sourceId && entry.sourceType == sourceType;
}

class PchHldplugin: public ::testing::Test
{
protected:
    PchHldplugin()
    {
        hldplugin.setUnsavedFiles({generatedFile});
        pchTask1.preIncludeSearchPath = testEnvironment.preIncludeSearchPath();
    }

    ClangBackEnd::FilePathId id(ClangBackEnd::FilePathView path)
    {
        return filePathCache.filePathId(path);
    }

    FilePathIds sorted(FilePathIds &&filePathIds)
    {
        std::sort(filePathIds.begin(), filePathIds.end());

        return std::move(filePathIds);
    }

protected:
    Sqlite::Database database{":memory:", Sqlite::JournalMode::Memory};
    ClangBackEnd::RefactoringDatabaseInitializer<Sqlite::Database> databaseInitializer{database};
    ClangBackEnd::FilePathCaching filePathCache{database};
    FilePath main1Path = TESTDATA_DIR "/builddependencycollector/project/main3.cpp";
    FilePath main2Path = TESTDATA_DIR "/builddependencycollector/project/main2.cpp";
    FilePath header1Path = TESTDATA_DIR "/builddependencycollector/project/header1.h";
    FilePath header2Path = TESTDATA_DIR "/builddependencycollector/project/header2.h";
    FilePath generatedFilePath = TESTDATA_DIR "/builddependencycollector/project/generated_file.h";
    TestEnvironment environment;
    FileContainer generatedFile{generatedFilePath.clone(), id(generatedFilePath), "#pragma once", {}};
    NiceMock<MockPchManagerClient> mockPchManagerClient;
    NiceMock<MockClangPathWatcher> mockClangPathWatcher;
    NiceMock<MockBuildDependenciesStorage> mockBuildDependenciesStorage;
    ClangBackEnd::PchHldplugin hldplugin{environment,
                                     filePathCache,
                                     mockPchManagerClient,
                                     mockClangPathWatcher,
                                     mockBuildDependenciesStorage};
    PchTask pchTask1{
        1,
        sorted({id(TESTDATA_DIR "/builddependencycollector/project/header2.h"),
                id(TESTDATA_DIR "/builddependencycollector/external/external1.h"),
                id(TESTDATA_DIR "/builddependencycollector/external/external2.h")}),
        sorted({id(TESTDATA_DIR "/builddependencycollector/system/system1.h"),
                id(TESTDATA_DIR "/builddependencycollector/system/system2.h"),
                id(generatedFilePath)}),
        sorted({id(TESTDATA_DIR "/builddependencycollector/external/external1.h"),
                id(TESTDATA_DIR "/builddependencycollector/external/external2.h"),
                id(generatedFilePath)}),
        sorted({id(TESTDATA_DIR "/builddependencycollector/project/header1.h"),
                id(TESTDATA_DIR "/builddependencycollector/project/header2.h"),
                id(generatedFilePath)}),
        sorted({id(main2Path), id(generatedFilePath)}),
        {},
        {},
        {{TESTDATA_DIR "/builddependencycollector/system", 2, IncludeSearchPathType::BuiltIn},
         {TESTDATA_DIR "/builddependencycollector/external", 1, IncludeSearchPathType::System}},
        {{TESTDATA_DIR "/builddependencycollector/project", 1, IncludeSearchPathType::User}},
    };
    TestEnvironment testEnvironment;
};
using PchHldpluginSlowTest = PchHldplugin;
using PchHldpluginVerySlowTest = PchHldplugin;

TEST_F(PchHldplugin, CreateProjectPartPchFileContent)
{
    auto content = hldplugin.generatePchIncludeFileContent(pchTask1.includes);

    ASSERT_THAT(std::string(content),
                AllOf(HasSubstr("#include \"" TESTDATA_DIR "/builddependencycollector/project/header2.h\"\n"),
                      HasSubstr("#include \"" TESTDATA_DIR "/builddependencycollector/external/external1.h\"\n"),
                      HasSubstr("#include \"" TESTDATA_DIR "/builddependencycollector/external/external2.h\"\n")));
}

TEST_F(PchHldplugin, CreateProjectPartClangCompilerArguments)
{
    auto arguments = hldplugin.generateClangCompilerArguments(std::move(pchTask1), "project.pch");

    ASSERT_THAT(arguments,
                ElementsAre("clang++",
                            "-w",
                            "-DNOMINMAX",
                            "-x",
                            "c++-header",
                            "-std=c++98",
                            "-nostdinc",
                            "-nostdinc++",
                            "-isystem",
                            toNativePath(TESTDATA_DIR "/preincludes"),
                            "-I",
                            toNativePath(TESTDATA_DIR "/builddependencycollector/project"),
                            "-isystem",
                            toNativePath(TESTDATA_DIR "/builddependencycollector/external"),
                            "-isystem",
                            toNativePath(TESTDATA_DIR "/builddependencycollector/system"),
                            "-o",
                            "project.pch"));
}

TEST_F(PchHldplugin, CreateProjectPartClangCompilerArgumentsWithSystemPch)
{
    pchTask1.systemPchPath = "system.pch";

    auto arguments = hldplugin.generateClangCompilerArguments(std::move(pchTask1), "project.pch");

    ASSERT_THAT(arguments,
                ElementsAre("clang++",
                            "-w",
                            "-DNOMINMAX",
                            "-x",
                            "c++-header",
                            "-std=c++98",
                            "-nostdinc",
                            "-nostdinc++",
                            "-isystem",
                            toNativePath(TESTDATA_DIR "/preincludes"),
                            "-I",
                            toNativePath(TESTDATA_DIR "/builddependencycollector/project"),
                            "-isystem",
                            toNativePath(TESTDATA_DIR "/builddependencycollector/external"),
                            "-isystem",
                            toNativePath(TESTDATA_DIR "/builddependencycollector/system"),
                            "-Xclang",
                            "-include-pch",
                            "-Xclang",
                            "system.pch",
                            "-o",
                            "project.pch"));
}

TEST_F(PchHldpluginVerySlowTest, ProjectPartPchsSendToPchManagerClient)
{
    hldplugin.generatePch(std::move(pchTask1));

    EXPECT_CALL(mockPchManagerClient,
                precompiledHeadersUpdated(
                    Field(&ClangBackEnd::PrecompiledHeadersUpdatedMessage::projectPartIds,
                          ElementsAre(Eq(hldplugin.projectPartPch().projectPartId)))));

    hldplugin.doInMainThreadAfterFinished();
}

TEST_F(PchHldpluginVerySlowTest, SourcesAreWatchedAfterSucess)
{
    hldplugin.generatePch(std::move(pchTask1));

    EXPECT_CALL(
        mockClangPathWatcher,
        updateIdPaths(UnorderedElementsAre(
            AllOf(Field(&ClangBackEnd::IdPaths::id, ProjectChunkId{1, SourceType::Source}),
                  Field(&ClangBackEnd::IdPaths::filePathIds, UnorderedElementsAre(id(main2Path)))),
            AllOf(Field(&ClangBackEnd::IdPaths::id, ProjectChunkId{1, SourceType::UserInclude}),
                  Field(&ClangBackEnd::IdPaths::filePathIds,
                        UnorderedElementsAre(
                            id(TESTDATA_DIR "/builddependencycollector/project/header1.h"),
                            id(TESTDATA_DIR "/builddependencycollector/project/header2.h")))),
            AllOf(Field(&ClangBackEnd::IdPaths::id, ProjectChunkId{1, SourceType::ProjectInclude}),
                  Field(&ClangBackEnd::IdPaths::filePathIds,
                        UnorderedElementsAre(
                            id(TESTDATA_DIR "/builddependencycollector/external/external1.h"),
                            id(TESTDATA_DIR "/builddependencycollector/external/external2.h")))),
            AllOf(Field(&ClangBackEnd::IdPaths::id, ProjectChunkId{1, SourceType::SystemInclude}),
                  Field(&ClangBackEnd::IdPaths::filePathIds,
                        UnorderedElementsAre(
                            id(TESTDATA_DIR "/builddependencycollector/system/system1.h"),
                            id(TESTDATA_DIR "/builddependencycollector/system/system2.h")))))));

    hldplugin.doInMainThreadAfterFinished();
}

TEST_F(PchHldpluginVerySlowTest, SourcesAreWatchedAfterFail)
{
    pchTask1.systemIncludeSearchPaths = {};
    pchTask1.projectIncludeSearchPaths = {};
    hldplugin.generatePch(std::move(pchTask1));

    EXPECT_CALL(
        mockClangPathWatcher,
        updateIdPaths(UnorderedElementsAre(
            AllOf(Field(&ClangBackEnd::IdPaths::id, ProjectChunkId{1, SourceType::Source}),
                  Field(&ClangBackEnd::IdPaths::filePathIds, UnorderedElementsAre(id(main2Path)))),
            AllOf(Field(&ClangBackEnd::IdPaths::id, ProjectChunkId{1, SourceType::UserInclude}),
                  Field(&ClangBackEnd::IdPaths::filePathIds,
                        UnorderedElementsAre(
                            id(TESTDATA_DIR "/builddependencycollector/project/header1.h"),
                            id(TESTDATA_DIR "/builddependencycollector/project/header2.h")))),
            AllOf(Field(&ClangBackEnd::IdPaths::id, ProjectChunkId{1, SourceType::ProjectInclude}),
                  Field(&ClangBackEnd::IdPaths::filePathIds,
                        UnorderedElementsAre(
                            id(TESTDATA_DIR "/builddependencycollector/external/external1.h"),
                            id(TESTDATA_DIR "/builddependencycollector/external/external2.h")))),
            AllOf(Field(&ClangBackEnd::IdPaths::id, ProjectChunkId{1, SourceType::SystemInclude}),
                  Field(&ClangBackEnd::IdPaths::filePathIds,
                        UnorderedElementsAre(
                            id(TESTDATA_DIR "/builddependencycollector/system/system1.h"),
                            id(TESTDATA_DIR "/builddependencycollector/system/system2.h")))))));

    hldplugin.doInMainThreadAfterFinished();
}

TEST_F(PchHldpluginVerySlowTest, PchCreationTimeStampsAreUpdated)
{
    hldplugin.generatePch(std::move(pchTask1));

    EXPECT_CALL(mockBuildDependenciesStorage, updatePchCreationTimeStamp(_, Eq(1)));

    hldplugin.doInMainThreadAfterFinished();
}

TEST_F(PchHldplugin, DoNothingInTheMainThreadIfGenerateWasNotCalled)
{
    EXPECT_CALL(mockBuildDependenciesStorage, updatePchCreationTimeStamp(_, _)).Times(0);
    EXPECT_CALL(mockClangPathWatcher, updateIdPaths(_)).Times(0);
    EXPECT_CALL(mockPchManagerClient, precompiledHeadersUpdated(_)).Times(0);

    hldplugin.doInMainThreadAfterFinished();
}

TEST_F(PchHldpluginVerySlowTest, ProjectPartPchForCreatesPchForPchTask)
{
    hldplugin.generatePch(std::move(pchTask1));

    ASSERT_THAT(hldplugin.projectPartPch(),
                AllOf(Field(&ProjectPartPch::projectPartId, Eq(1)),
                      Field(&ProjectPartPch::pchPath, Not(IsEmpty())),
                      Field(&ProjectPartPch::lastModified, Not(Eq(-1)))));
}

TEST_F(PchHldpluginVerySlowTest, ProjectPartPchCleared)
{
    hldplugin.generatePch(std::move(pchTask1));

    hldplugin.clear();

    ASSERT_FALSE(hldplugin.projectPartPch().isValid());
}

TEST_F(PchHldpluginVerySlowTest, WatchedSystemIncludesCleared)
{
    hldplugin.generatePch(std::move(pchTask1));

    hldplugin.clear();

    ASSERT_THAT(hldplugin.watchedSystemIncludes(), IsEmpty());
}

TEST_F(PchHldpluginVerySlowTest, WatchedProjectIncludesCleared)
{
    hldplugin.generatePch(std::move(pchTask1));

    hldplugin.clear();

    ASSERT_THAT(hldplugin.watchedProjectIncludes(), IsEmpty());
}

TEST_F(PchHldpluginVerySlowTest, WatchedUserIncludesCleared)
{
    hldplugin.generatePch(std::move(pchTask1));

    hldplugin.clear();

    ASSERT_THAT(hldplugin.watchedUserIncludes(), IsEmpty());
}
TEST_F(PchHldpluginVerySlowTest, WatchedSourcesCleared)
{
    hldplugin.generatePch(std::move(pchTask1));

    hldplugin.clear();

    ASSERT_THAT(hldplugin.watchedSources(), IsEmpty());
}
TEST_F(PchHldpluginVerySlowTest, ClangToolCleared)
{
    hldplugin.generatePch(std::move(pchTask1));

    hldplugin.clear();

    ASSERT_TRUE(hldplugin.clangTool().isClean());
}

TEST_F(PchHldpluginVerySlowTest, FaultyProjectPartPchForCreatesFaultyPchForPchTask)
{
    PchTask faultyPchTask{
        0,
        {id(TESTDATA_DIR "/builddependencycollector/project/faulty.cpp")},
        {},
        {},
        {},
        {},
        {{"DEFINE", "1", 1}},
        {},
        {{TESTDATA_DIR "/builddependencycollector/external", 1, IncludeSearchPathType::System}},
        {{TESTDATA_DIR "/builddependencycollector/project", 1, IncludeSearchPathType::User}}};

    hldplugin.generatePch(std::move(faultyPchTask));

    ASSERT_THAT(hldplugin.projectPartPch(),
                AllOf(Field(&ProjectPartPch::projectPartId, Eq(0)),
                      Field(&ProjectPartPch::pchPath, IsEmpty()),
                      Field(&ProjectPartPch::lastModified, Gt(0))));
}

TEST_F(PchHldpluginSlowTest, NoIncludes)
{
    pchTask1.includes = {};

    hldplugin.generatePch(std::move(pchTask1));

    ASSERT_THAT(hldplugin.projectPartPch(),
                AllOf(Field(&ProjectPartPch::projectPartId, Eq(pchTask1.projectPartId())),
                      Field(&ProjectPartPch::pchPath, IsEmpty()),
                      Field(&ProjectPartPch::lastModified, Gt(0))));
}

TEST_F(PchHldpluginSlowTest, NoIncludesInTheMainThreadCalls)
{
    pchTask1.includes = {};
    hldplugin.generatePch(std::move(pchTask1));
    EXPECT_CALL(mockPchManagerClient,
                precompiledHeadersUpdated(
                    Field(&ClangBackEnd::PrecompiledHeadersUpdatedMessage::projectPartIds,
                          ElementsAre(Eq(hldplugin.projectPartPch().projectPartId)))));
    EXPECT_CALL(
        mockClangPathWatcher,
        updateIdPaths(UnorderedElementsAre(
            AllOf(Field(&ClangBackEnd::IdPaths::id, ProjectChunkId{1, SourceType::Source}),
                  Field(&ClangBackEnd::IdPaths::filePathIds, UnorderedElementsAre(id(main2Path)))),
            AllOf(Field(&ClangBackEnd::IdPaths::id, ProjectChunkId{1, SourceType::UserInclude}),
                  Field(&ClangBackEnd::IdPaths::filePathIds,
                        UnorderedElementsAre(
                            id(TESTDATA_DIR "/builddependencycollector/project/header1.h"),
                            id(TESTDATA_DIR "/builddependencycollector/project/header2.h")))),
            AllOf(Field(&ClangBackEnd::IdPaths::id, ProjectChunkId{1, SourceType::ProjectInclude}),
                  Field(&ClangBackEnd::IdPaths::filePathIds,
                        UnorderedElementsAre(
                            id(TESTDATA_DIR "/builddependencycollector/external/external1.h"),
                            id(TESTDATA_DIR "/builddependencycollector/external/external2.h")))),
            AllOf(Field(&ClangBackEnd::IdPaths::id, ProjectChunkId{1, SourceType::SystemInclude}),
                  Field(&ClangBackEnd::IdPaths::filePathIds,
                        UnorderedElementsAre(
                            id(TESTDATA_DIR "/builddependencycollector/system/system1.h"),
                            id(TESTDATA_DIR "/builddependencycollector/system/system2.h")))))));
    EXPECT_CALL(mockBuildDependenciesStorage, updatePchCreationTimeStamp(Gt(0), Eq(1)));

    hldplugin.doInMainThreadAfterFinished();
}

TEST_F(PchHldpluginVerySlowTest, GeneratedFile)
{
    hldplugin.clear();

    hldplugin.setUnsavedFiles({generatedFile});

    ASSERT_FALSE(hldplugin.clangTool().isClean());
}
}
