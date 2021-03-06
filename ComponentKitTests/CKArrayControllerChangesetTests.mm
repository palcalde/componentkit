/*
 *  Copyright (c) 2014-present, Facebook, Inc.
 *  All rights reserved.
 *
 *  This source code is licensed under the BSD-style license found in the
 *  LICENSE file in the root directory of this source tree. An additional grant
 *  of patent rights can be found in the PATENTS file in the same directory.
 *
 */

#import <XCTest/XCTest.h>

#import <ComponentKit/CKArrayControllerChangeset.h>

using namespace CK::ArrayController;

typedef NS_ENUM(NSUInteger, CommandType) {
  CommandTypeSection,
  CommandTypeItem
};

@interface CKArrayControllerIndexPathTests : XCTestCase

@end

@implementation CKArrayControllerIndexPathTests

- (void)testDefaultConstructor
{
  IndexPath indexPath;
  XCTAssertEqual(indexPath.item, NSNotFound, @"");
  XCTAssertEqual(indexPath.section, NSNotFound, @"");
}

- (void)testToNSIndexPathWithNoInput
{
  IndexPath indexPath;
  XCTAssertEqualObjects(indexPath.toNSIndexPath(), [NSIndexPath indexPathForItem:NSNotFound inSection:NSNotFound], @"");
}

- (void)testToNSIndexPathWithNonZeroInput
{
  IndexPath indexPath = {20, 10};
  XCTAssertEqualObjects(indexPath.toNSIndexPath(), [NSIndexPath indexPathForItem:10 inSection:20], @"");
}

- (void)testNSIndexPathConstructorWithNonNilIndexPath
{
  IndexPath indexPath = {[NSIndexPath indexPathForItem:10 inSection:20]};
  IndexPath expected = {20, 10};
  XCTAssertTrue(expected == indexPath, @"");
}

- (void)testNSIndexPathConstructorWithNilIndexPath
{
  IndexPath indexPath = IndexPath(nil);
  IndexPath expected = {NSNotFound, NSNotFound};
  XCTAssertTrue(expected == indexPath, @"");
}

@end

@interface CKArrayControllerInputItemsTests : XCTestCase

@end

@implementation CKArrayControllerInputItemsTests

- (void)testSize
{
  Input::Items items;
  XCTAssertTrue(items.size() == 0, @"");

  items.insert({0, 0}, @0);
  items.insert({1, 0}, @1);
  items.update({2, 0}, @2);
  items.update({3, 0}, @3);
  items.remove({4, 0});
  items.remove({5, 0});
  XCTAssertTrue(items.size() == 6, @"");
}

/**
 The point? Catching bugs at the **source** when we build our changeset, not later when we try to apply it.
 */
- (void)testThrowsOnDuplicateInsertOfSameIndexPath
{
  Input::Items items;
  items.insert({0, 0}, @1);
  XCTAssertThrowsSpecificNamed(items.insert({0, 0}, @2), NSException, NSInternalInconsistencyException, @"");
}

- (void)testThrowsOnDuplicateRemovalOfSameIndexPath
{
  Input::Items items;
  items.remove({0, 0});
  XCTAssertThrowsSpecificNamed(items.remove({0, 0}), NSException, NSInternalInconsistencyException, @"");
}

- (void)testThrowsOnDuplicateUpdateOfSameIndexPath
{
  Input::Items items;
  items.update({0, 0}, @1);
  XCTAssertThrowsSpecificNamed(items.update({0, 0}, @2), NSException, NSInternalInconsistencyException, @"");
}

- (void)testDoesNotThrowOnRemoveAndInsertWithSameIndexPath
{
  {
    Input::Items items;
    items.insert({0, 0}, @1);
    XCTAssertNoThrow(items.remove({0, 0}), @"Insertions can share the same indexes with removals or updates.");
  }

  {
    Input::Items items;
    items.remove({0, 0});
    XCTAssertNoThrow(items.insert({0, 0}, @1), @"Insertions can share the same indexes with removals or updates.");
  }
}

- (void)testDoesNotThrowOnUpdateAndInsertWithSameIndexPath
{
  {
    Input::Items items;
    items.update({0, 0}, @1);
    XCTAssertNoThrow(items.insert({0, 0}, @0),  @"Insertions can share the same indexes with removals or updates.");
  }

  {
    Input::Items items;
    items.insert({0, 0}, @0);
    XCTAssertNoThrow(items.update({0, 0}, @1), @"Insertions can share the same indexes with removals or updates.");
  }
}

- (void)testThrowsOnUpdateAndRemoveWithSameIndexPath
{
  {
    Input::Items items;
    items.update({0, 0}, @1);
    XCTAssertThrowsSpecificNamed(items.remove({0, 0}), NSException, NSInternalInconsistencyException, @"");
  }

  {
    Input::Items items;
    items.remove({0, 0});
    XCTAssertThrowsSpecificNamed(items.update({0, 0}, @1), NSException, NSInternalInconsistencyException, @"");
  }
}

- (void)testInsertions
{
  Input::Items items;
  items.insert({0, 0}, @1);
  items.insert({1, 1}, @2);
  
  NSDictionary *expectedInsertions = @{[NSIndexPath indexPathForItem:0 inSection:0]: @1,
                                       [NSIndexPath indexPathForItem:1 inSection:1]: @2};
  NSDictionary *expectedUpdates = @{};
  NSSet *expectedRemovals = [NSSet set];
  
  XCTAssertEqualObjects(expectedInsertions, items.insertions());
  XCTAssertEqualObjects(expectedRemovals, items.removals());
  XCTAssertEqualObjects(expectedUpdates, items.updates());
}

- (void)testUpdates
{
  Input::Items items;
  items.update({0, 0}, @1);
  items.update({1, 1}, @2);
  
  NSDictionary *expectedInsertions = @{};
  NSDictionary *expectedUpdates = @{[NSIndexPath indexPathForItem:0 inSection:0]: @1,
                                    [NSIndexPath indexPathForItem:1 inSection:1]: @2};;
  NSSet *expectedRemovals = [NSSet set];
  
  XCTAssertEqualObjects(expectedInsertions, items.insertions());
  XCTAssertEqualObjects(expectedRemovals, items.removals());
  XCTAssertEqualObjects(expectedUpdates, items.updates());
}

- (void)testRemovals
{
  Input::Items items;
  items.remove({0, 0});
  items.remove({1, 1});
  
  NSDictionary *expectedInsertions = @{};
  NSDictionary *expectedUpdates = @{};
  NSSet *expectedRemovals = [NSSet setWithArray:@[[NSIndexPath indexPathForItem:0 inSection:0], [NSIndexPath indexPathForItem:1 inSection:1]]];
  
  XCTAssertEqualObjects(expectedInsertions, items.insertions());
  XCTAssertEqualObjects(expectedRemovals, items.removals());
  XCTAssertEqualObjects(expectedUpdates, items.updates());
}


@end

@interface CKArrayControllerInputSectionsTests : XCTestCase
@end

@implementation CKArrayControllerInputSectionsTests

/**
 The point? Catching bugs at the **source** when we build our changeset, not later when we try to apply it.
 */
- (void)testThrowsOnDuplicateInsertOfSameIndex
{
  Sections sections;
  sections.insert(0);
  XCTAssertThrowsSpecificNamed(sections.insert(0), NSException, NSInternalInconsistencyException, @"");
}

- (void)testThrowsOnDuplicateRemovalOfSameIndex
{
  Sections sections;
  sections.remove(0);
  XCTAssertThrowsSpecificNamed(sections.remove(0), NSException, NSInternalInconsistencyException, @"");
}

- (void)testDoesNotThrowOnDuplicationCommandOfSameIndexForDifferentOperation
{
  {
    Sections sections;
    sections.insert(0);
    XCTAssertNoThrow(sections.remove(0), @"Removals and insertions can share the same indexes.");
  }

  {
    Sections sections;
    sections.remove(0);
    XCTAssertNoThrow(sections.insert(0), @"Removals and insertions can share the same indexes.");
  }
}

- (void)testInsertion
{
  Sections sections;
  sections.insert(0);
  sections.insert(1);
  
  XCTAssertEqualObjects([NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)], sections.insertions());
  XCTAssertEqualObjects([NSIndexSet indexSet], sections.removals());
}

- (void)testRemoval
{
  Sections sections;
  sections.remove(0);
  sections.remove(1);
  
  XCTAssertEqualObjects([NSIndexSet indexSet], sections.insertions());
  XCTAssertEqualObjects([NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 2)], sections.removals());
}

@end

@interface CKArrayControllerInputChangesetTests : XCTestCase
@end

@implementation CKArrayControllerInputChangesetTests

- (void)testDoesNotThrowWithNilEnumeratorArguments
{
  Input::Changeset changeset = {{}, {}};

  Sections::Enumerator sectionsEnumerator =
  ^(NSIndexSet *sectionIndexes, CKArrayControllerChangeType type, BOOL *stop) {};

  Input::Items::Enumerator itemsEnumerator =
  ^(NSInteger section, NSIndexSet *indexes, NSArray *objects, CKArrayControllerChangeType type, BOOL *stop) {};

  XCTAssertNoThrow(changeset.enumerate(nil, itemsEnumerator), @"");
  XCTAssertNoThrow(changeset.enumerate(sectionsEnumerator, nil), @"");
}

static Input::Changeset exampleInputChangeset(void)
{
  Sections sections;
  sections.insert(2);
  sections.insert(0);
  sections.remove(15);
  sections.remove(5);

  Input::Items items;
  items.insert({2, 1}, @1);
  items.insert({2, 0}, @2);
  items.insert({1, 15}, @3);
  items.insert({1, 5}, @4);
  items.update({6, 6}, @5);
  items.update({6, 5}, @5);
  items.remove({15, 9});
  items.remove({15, 8});

  return {sections, items};
}

/**
 Enumerating input should order commands (see header) such that we can apply the changes to the internal arrays of
 CKSectionedArrayController **without** having to change any of the index paths in the input commands.
 */
- (void)testEnumerationOrdersSectionAndItemsCommandsCorrectly
{
  __block std::vector<std::pair<CommandType, CKArrayControllerChangeType>> commands;

  Sections::Enumerator sectionsEnumerator =
  ^(NSIndexSet *sectionIndexes, CKArrayControllerChangeType type, BOOL *stop) {
    commands.push_back({CommandTypeSection, type});
  };

  Input::Items::Enumerator itemsEnumerator =
  ^(NSInteger section, NSIndexSet *indexes, NSArray *objects, CKArrayControllerChangeType type, BOOL *stop) {
    commands.push_back({CommandTypeItem, type});
  };

  Input::Changeset changeset = exampleInputChangeset();
  changeset.enumerate(sectionsEnumerator, itemsEnumerator);

  std::vector<std::pair<CommandType, CKArrayControllerChangeType>> expected = {
    {CommandTypeItem, CKArrayControllerChangeTypeUpdate},
    {CommandTypeItem, CKArrayControllerChangeTypeDelete},
    {CommandTypeSection, CKArrayControllerChangeTypeDelete},
    {CommandTypeSection, CKArrayControllerChangeTypeInsert},
    {CommandTypeItem, CKArrayControllerChangeTypeInsert},
    {CommandTypeItem, CKArrayControllerChangeTypeInsert}, // We insert items in 2 sections, so we expect 2 callbacks.
  };

  XCTAssertTrue(commands == expected, @"Commands received in incorrect order");
}


- (void)testSectionCommandsAreEnumeratedOnlyIfNecessary
{
  Sections sections;
  Input::Items items;

  Input::Changeset changeset = {sections, items};

  __block BOOL insertions = NO;
  __block BOOL removals = NO;

  Sections::Enumerator sectionsEnumerator =
  ^(NSIndexSet *sectionIndexes, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeInsert) {
      insertions = YES;
    }
    if (type == CKArrayControllerChangeTypeDelete) {
      removals = YES;
    }
  };

  Input::Items::Enumerator itemsEnumerator =
    ^(NSInteger section, NSIndexSet *indexes, NSArray *objects, CKArrayControllerChangeType type, BOOL *stop) {};

  changeset.enumerate(sectionsEnumerator, itemsEnumerator);

  XCTAssertFalse(insertions, @"If there are no insertions, the insertions block should not be called");
  XCTAssertFalse(removals, @"If there are no removals, the removal block should not be called");
}

- (void)testEachCommandOfTheSameTypeIsPassedToEnumerationBlocks
{
  Sections::Enumerator sectionsEnumerator =
  ^(NSIndexSet *sectionIndexes, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeInsert) {
      NSMutableIndexSet *expected = [[NSMutableIndexSet alloc] init];
      [expected addIndex:0];
      [expected addIndex:2];
      XCTAssertEqualObjects(sectionIndexes, expected, @"");
    }
    if (type == CKArrayControllerChangeTypeDelete) {
      NSMutableIndexSet *expected = [[NSMutableIndexSet alloc] init];
      [expected addIndex:15];
      [expected addIndex:5];
      XCTAssertEqualObjects(sectionIndexes, expected, @"");
    }
  };

  Input::Items::Enumerator itemsEnumerator =
  ^(NSInteger section, NSIndexSet *indexes, NSArray *objects, CKArrayControllerChangeType type, BOOL *stop) {

    NSMutableIndexSet *expected = [[NSMutableIndexSet alloc] init];

    if (type == CKArrayControllerChangeTypeInsert) {
      if (section == 1) {
        [expected addIndex:5];
        [expected addIndex:15];
        XCTAssertEqualObjects(indexes, expected, @"");
      }
      if (section == 2) {
        [expected addIndex:0];
        [expected addIndex:1];
        XCTAssertEqualObjects(indexes, expected, @"");
      }
    }
    if (type == CKArrayControllerChangeTypeDelete) {
      [expected addIndex:8];
      [expected addIndex:9];
      XCTAssertEqualObjects(indexes, expected, @"");
    }
    if (type == CKArrayControllerChangeTypeUpdate) {
      [expected addIndex:5];
      [expected addIndex:6];
      XCTAssertEqualObjects(indexes, expected, @"");
    }
  };

  Input::Changeset changeset = exampleInputChangeset();
  changeset.enumerate(sectionsEnumerator, itemsEnumerator);
}

- (void)testMapNULLBlock
{
  Input::Changeset input = exampleInputChangeset();
  Input::Changeset mapped = input.map(NULL);
  XCTAssertTrue(input == mapped, @"");
}

- (void)testMapThrowsOnNilReturnValueFromBlock
{
  Input::Changeset input = exampleInputChangeset();
  Input::Changeset::Mapper mapper = ^id<NSObject>(const IndexPath &indexPath, id<NSObject> object, CKArrayControllerChangeType type, BOOL *stop) {
    return nil;
  };
  XCTAssertThrowsSpecificNamed(input.map(mapper), NSException, NSInternalInconsistencyException, @"");
}

- (void)testMapIdentity
{
  Input::Changeset input = exampleInputChangeset();
  Input::Changeset::Mapper mapper = ^id<NSObject>(const IndexPath &indexPath, id<NSObject> object, CKArrayControllerChangeType type, BOOL *stop) {
    return object;
  };
  Input::Changeset mapped = input.map(mapper);
  XCTAssertTrue(mapped == input, @"");
}

- (void)testMap
{
  Input::Changeset input = exampleInputChangeset();
  Input::Changeset::Mapper mapper = ^id<NSObject>(const IndexPath &indexPath, id<NSObject> object, CKArrayControllerChangeType type, BOOL *stop) {
    return @([(NSNumber *)object intValue] + 1);
  };

  Input::Changeset mapped = input.map(mapper);

  Sections expectedSections;
  expectedSections.insert(2);
  expectedSections.insert(0);
  expectedSections.remove(15);
  expectedSections.remove(5);

  Input::Items expectedItems;
  expectedItems.insert({2, 1}, @2);
  expectedItems.insert({2, 0}, @3);
  expectedItems.insert({1, 15}, @4);
  expectedItems.insert({1, 5}, @5);
  expectedItems.update({6, 6}, @6);
  expectedItems.update({6, 5}, @6);
  expectedItems.remove({15, 9});
  expectedItems.remove({15, 8});

  Input::Changeset expected = {expectedSections, expectedItems};

  XCTAssertTrue(mapped == expected, @"");
}

- (void)testMapIndex
{
  Input::Changeset input = exampleInputChangeset();
  
  const NSInteger sectionOffset = 5;
  const NSInteger itemOffset = 2;
  Input::Changeset mapped = input.mapIndex(
                                           ^(const NSInteger sectionIndex, CKArrayControllerChangeType type) {
                                             return sectionIndex + sectionOffset;
                                           },
                                           ^(const IndexPath &indexPath, CKArrayControllerChangeType type) {
                                             return IndexPath(indexPath.section + sectionOffset, indexPath.item + itemOffset);
                                           });
  Sections expectedSections;
  expectedSections.insert(2+sectionOffset);
  expectedSections.insert(0+sectionOffset);
  expectedSections.remove(15+sectionOffset);
  expectedSections.remove(5+sectionOffset);
  
  Input::Items expectedItems;
  expectedItems.insert({2+sectionOffset, 1+itemOffset}, @1);
  expectedItems.insert({2+sectionOffset, 0+itemOffset}, @2);
  expectedItems.insert({1+sectionOffset, 15+itemOffset}, @3);
  expectedItems.insert({1+sectionOffset, 5+itemOffset}, @4);
  expectedItems.update({6+sectionOffset, 6+itemOffset}, @5);
  expectedItems.update({6+sectionOffset, 5+itemOffset}, @5);
  expectedItems.remove({15+sectionOffset, 9+itemOffset});
  expectedItems.remove({15+sectionOffset, 8+itemOffset});
  
  Input::Changeset expected = {expectedSections, expectedItems};
  
  XCTAssertTrue(mapped == expected, @"");
}

@end

@interface CKArrayControllerOutputChangesetTests : XCTestCase
@end

@implementation CKArrayControllerOutputChangesetTests

- (void)testDoesNotThrowWithNilEnumeratorArguments
{
  Output::Changeset changeset = {{}, {}};

  Sections::Enumerator sectionsEnumerator =
  ^(NSIndexSet *sectionIndexes, CKArrayControllerChangeType type, BOOL *stop) {};

  Output::Items::Enumerator itemsEnumerator =
  ^(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {};

  XCTAssertNoThrow(changeset.enumerate(nil, itemsEnumerator), @"");
  XCTAssertNoThrow(changeset.enumerate(sectionsEnumerator, nil), @"");
}

static Output::Changeset exampleOutputChangeset(void)
{
  Sections sections;
  sections.insert(2);
  sections.insert(0);
  sections.insert(1);
  sections.remove(5);
  sections.remove(6);
  sections.remove(7);

  Output::Items items;
  items.insert({{0, 1}, @0});
  items.insert({{0, 0}, @1});
  items.insert({{2, 0}, @2});
  items.insert({{2, 1}, @3});
  items.remove({{15, 10}, @4});
  items.remove({{15, 9}, @5});
  items.remove({{16, 4}, @6});
  items.remove({{16, 5}, @7});
  items.update({{7, 6}, @8, @9});
  items.update({{7, 5}, @8, @9});
  items.update({{6, 3}, @8, @9});
  items.update({{6, 4}, @8, @9});

  return {sections, items};
}

- (void)testEnumerationOrdersSectionAndItemsCommandsCorrectly
{
  Output::Changeset changeset = exampleOutputChangeset();

  NSMutableArray *allCommands = [[NSMutableArray alloc] init];

  Sections::Enumerator sectionsEnumerator =
  ^(NSIndexSet *sectionIndexes, CKArrayControllerChangeType type, BOOL *stop) {
    [allCommands addObject:@[@(CommandTypeSection), @(type)]];
  };

  Output::Items::Enumerator itemsEnumerator =
  ^(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    [allCommands addObject:@[@(CommandTypeItem), @(type)]];
  };

  changeset.enumerate(sectionsEnumerator, itemsEnumerator);

  NSArray *expected = @[
                        @[@(CommandTypeItem), @(CKArrayControllerChangeTypeUpdate)],
                        @[@(CommandTypeItem), @(CKArrayControllerChangeTypeDelete)],
                        @[@(CommandTypeSection), @(CKArrayControllerChangeTypeDelete)],
                        @[@(CommandTypeSection), @(CKArrayControllerChangeTypeInsert)],
                        @[@(CommandTypeItem), @(CKArrayControllerChangeTypeInsert)],
                        ];

  NSOrderedSet *commands = [[NSOrderedSet alloc] initWithArray:allCommands];

  XCTAssertEqualObjects([commands array], expected, @"Commands received in incorrect order");
}

- (void)testSectionCommandsAreEnumeratedInOrder
{
  Output::Changeset changeset = exampleOutputChangeset();

  __block NSIndexSet *insertions;
  __block NSIndexSet *removals;

  Sections::Enumerator sectionsEnumerator =
  ^(NSIndexSet *sectionIndexes, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeInsert) {
      insertions = sectionIndexes;
    }
    if (type == CKArrayControllerChangeTypeDelete) {
      removals = sectionIndexes;
    }
  };

  Output::Items::Enumerator itemsEnumerator =
  ^(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {};

  changeset.enumerate(sectionsEnumerator, itemsEnumerator);

  NSIndexSet *expectedInsertions = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(0, 3)];
  NSIndexSet *expectedRemovals = [NSIndexSet indexSetWithIndexesInRange:NSMakeRange(5, 3)];

  XCTAssertEqualObjects(insertions, expectedInsertions, @"");
  XCTAssertEqualObjects(removals, expectedRemovals, @"");
}

- (void)testItemCommandsAreEnumeratedInOrder
{
  Output::Changeset changeset = exampleOutputChangeset();

  Sections::Enumerator sectionsEnumerator =
  ^(NSIndexSet *sectionIndexes, CKArrayControllerChangeType type, BOOL *stop) {};

  __block std::set<Output::Change> insertions;
  __block std::set<Output::Change> removals;
  __block std::set<Output::Change> updates;

  Output::Items::Enumerator itemsEnumerator =
  ^(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeInsert) {
      insertions.insert(change);
    }
    if (type == CKArrayControllerChangeTypeDelete) {
      removals.insert(change);
    }
    if (type == CKArrayControllerChangeTypeUpdate) {
      updates.insert(change);
    }
  };

  changeset.enumerate(sectionsEnumerator, itemsEnumerator);

  std::set<Output::Change> expectedInsertions = {
    {{0, 0}, nil, @1},
    {{0, 1}, nil, @0},
    {{2, 0}, nil, @2},
    {{2, 1}, nil, @3}
  };

  std::set<Output::Change> expectedRemovals = {
    {{15, 9}, @5, nil},
    {{15, 10}, @4, nil},
    {{16, 4}, @6, nil},
    {{16, 5}, @7, nil}
  };

  std::set<Output::Change> expectedUpdates = {
    {{7, 5}, @8, @9},
    {{7, 6}, @8, @9},
    {{6, 3}, @8, @9},
    {{6, 4}, @8, @9}
  };

  XCTAssertTrue(insertions == expectedInsertions, @"");
  XCTAssertTrue(removals == expectedRemovals, @"");
  XCTAssertTrue(updates == expectedUpdates, @"");
}

- (void)testMapNULLBlock
{
  Output::Changeset output = exampleOutputChangeset();
  Output::Changeset mapped = output.map(NULL);
  XCTAssertTrue(output == mapped, @"");
}

- (void)testMapThrowsOnNonNilInsertBefore
{
  Output::Changeset output = exampleOutputChangeset();
  Output::Changeset::Mapper mapper =
  ^Output::Changeset::BeforeAfterPair(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeInsert) {
      return {@0, nil};
    } else {
      return {change.before, change.after};
    }
  };
  XCTAssertThrowsSpecificNamed(output.map(mapper), NSException, NSInternalInconsistencyException, @"");
}

- (void)testMapThrowsOnNilInsertAfter
{
  Output::Changeset output = exampleOutputChangeset();
  Output::Changeset::Mapper mapper =
  ^Output::Changeset::BeforeAfterPair(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeInsert) {
      return {nil, nil};
    } else {
      return {change.before, change.after};
    }
  };
  XCTAssertThrowsSpecificNamed(output.map(mapper), NSException, NSInternalInconsistencyException, @"");
}

- (void)testMapThrowsOnNilDeleteBefore
{
  Output::Changeset output = exampleOutputChangeset();
  Output::Changeset::Mapper mapper =
  ^Output::Changeset::BeforeAfterPair(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeDelete) {
      return {nil, nil};
    } else {
      return {change.before, change.after};
    }
  };
  XCTAssertThrowsSpecificNamed(output.map(mapper), NSException, NSInternalInconsistencyException, @"");
}

- (void)testMapThrowsOnNonNilDeleteAfter
{
  Output::Changeset output = exampleOutputChangeset();
  Output::Changeset::Mapper mapper =
  ^Output::Changeset::BeforeAfterPair(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeDelete) {
      return {@0, @1};
    } else {
      return {change.before, change.after};
    }
  };
  XCTAssertThrowsSpecificNamed(output.map(mapper), NSException, NSInternalInconsistencyException, @"");
}

- (void)testMapThrowsOnNilUpdateBefore
{
  Output::Changeset output = exampleOutputChangeset();
  Output::Changeset::Mapper mapper =
  ^Output::Changeset::BeforeAfterPair(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeUpdate) {
      return {nil, @0};
    } else {
      return {change.before, change.after};
    }
  };
  XCTAssertThrowsSpecificNamed(output.map(mapper), NSException, NSInternalInconsistencyException, @"");
}

- (void)testMapThrowsOnNilUpdateAfter
{
  Output::Changeset output = exampleOutputChangeset();
  Output::Changeset::Mapper mapper =
  ^Output::Changeset::BeforeAfterPair(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeUpdate) {
      return {@0, nil};
    } else {
      return {change.before, change.after};
    }
  };
  XCTAssertThrowsSpecificNamed(output.map(mapper), NSException, NSInternalInconsistencyException, @"");
}

- (void)testMapIdentity
{
  Output::Changeset output = exampleOutputChangeset();
  Output::Changeset::Mapper mapper =
  ^Output::Changeset::BeforeAfterPair(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    return {change.before, change.after};
  };
  Output::Changeset mapped = output.map(mapper);
  XCTAssertTrue(mapped == output, @"");
}

- (void)testMap
{
  Output::Changeset output = exampleOutputChangeset();
  Output::Changeset::Mapper mapper =
  ^Output::Changeset::BeforeAfterPair(const Output::Change &change, CKArrayControllerChangeType type, BOOL *stop) {
    if (type == CKArrayControllerChangeTypeUpdate) {
      return {@([(NSNumber *)change.before integerValue] + 1), @([(NSNumber *)change.after integerValue] + 1)};
    }
    if (type == CKArrayControllerChangeTypeDelete) {
      return {@([(NSNumber *)change.before integerValue] + 1), nil};
    }
    if (type == CKArrayControllerChangeTypeInsert) {
      return {nil, @([(NSNumber *)change.after integerValue] + 1)};
    }
    XCTFail(@"Unknown change type %lu", (unsigned long)type);
    return {nil, nil};
  };

  Output::Changeset mapped = output.map(mapper);

  Sections expectedSections;
  expectedSections.insert(2);
  expectedSections.insert(0);
  expectedSections.insert(1);
  expectedSections.remove(5);
  expectedSections.remove(6);
  expectedSections.remove(7);

  Output::Items expectedItems;
  expectedItems.insert({{0, 1}, @1});
  expectedItems.insert({{0, 0}, @2});
  expectedItems.insert({{2, 0}, @3});
  expectedItems.insert({{2, 1}, @4});
  expectedItems.remove({{15, 10}, @5});
  expectedItems.remove({{15, 9}, @6});
  expectedItems.remove({{16, 4}, @7});
  expectedItems.remove({{16, 5}, @8});
  expectedItems.update({{7, 6}, @9, @10});
  expectedItems.update({{7, 5}, @9, @10});
  expectedItems.update({{6, 3}, @9, @10});
  expectedItems.update({{6, 4}, @9, @10});

  Output::Changeset expected = {expectedSections, expectedItems};

  XCTAssertTrue(mapped == expected, @"");
}

@end
