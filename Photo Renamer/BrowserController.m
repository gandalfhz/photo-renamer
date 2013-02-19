//
//  Copyright (c) 2012-2013 Gandalf Hernandez.
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
// http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.

#import "BrowserItem.h"
#import "BrowserController.h"

@interface BrowserController ()
{
  NSMutableArray *_images;
  NSString *_lastNormalizedPath;
  NSUInteger _previewIndex;
  NSCalendar *_calendar;
  NSMutableDictionary *_timestampCache;
}

@property (weak) NSString *previewMenuItemTitle;

@end

@implementation BrowserController

- (void)awakeFromNib
{
  [self.browser setConstrainsToOriginalSize:YES];
  [self.browser setAnimates:YES];

  NSFont *font = [NSFont fontWithName:@"LucidaGrande" size:9];
  NSMutableDictionary *dictionary = [self.browser valueForKey:IKImageBrowserCellsTitleAttributesKey];
  [dictionary setValue:font forKey:@"NSFont"];
  [dictionary setObject:[NSColor colorWithDeviceRed:0.95 green:0.95 blue:0.95 alpha:1] forKey:NSForegroundColorAttributeName];

  dictionary = [self.browser valueForKey:IKImageBrowserCellsHighlightedTitleAttributesKey];
  [dictionary setValue:font forKey:@"NSFont"];
  [dictionary setObject:[NSColor colorWithDeviceRed:0.95 green:0.95 blue:0.95 alpha:1] forKey:NSForegroundColorAttributeName];

  dictionary = [self.browser valueForKey:IKImageBrowserCellsSubtitleAttributesKey];
  [dictionary setValue:font forKey:@"NSFont"];
  [dictionary setObject:[NSColor colorWithDeviceRed:0.75 green:0.75 blue:0.75 alpha:1] forKey:NSForegroundColorAttributeName];

  [self.browser setValue:[NSColor colorWithDeviceRed:0.25 green:0.25 blue:0.25 alpha:1.0]
                      forKey:IKImageBrowserBackgroundColorKey];

  [self.browser setValue:[NSColor colorWithDeviceRed:0.35 green:0.35 blue:0.35 alpha:1.0]
                      forKey:IKImageBrowserSelectionColorKey];

  [self.browser setNeedsDisplay:YES];

  NSString *folder = [[NSUserDefaults standardUserDefaults] stringForKey:@"folder"];
  self.folder.stringValue = folder ? folder : NSHomeDirectory();

  NSString *scheme = [[NSUserDefaults standardUserDefaults] stringForKey:@"scheme"];
  self.scheme.stringValue = scheme ? scheme : @"[Y]-[M]-[D] [h].[m] Location.[E]";

  // Default value is 0, so we have min zoom as 0.05 to discern between no value and a value
  float zoom = [[NSUserDefaults standardUserDefaults] floatForKey:@"zoom"];
  self.slider.floatValue = self.browser.zoomValue = zoom > 0.05 ? zoom : 0.6;

  self.preview.hasHorizontalScroller = YES;
  self.preview.hasVerticalScroller = YES;
  self.preview.autohidesScrollers = NO;

  _calendar = [NSCalendar currentCalendar];
  _timestampCache = [[NSMutableDictionary alloc] init];

  self.previewMenuItemTitle = @"View image";

  [self refresh];
}

- (void) windowDidResize:(NSNotification *)notification
{
  if (!self.browser.isHidden) {
    // we want the window sizing to affect the zooming
    self.browser.zoomValue = self.slider.floatValue;
  } else {
    // If we are viewing an image, a resizing changes the minimum slider value,
    // since we want a full zoom out to fit the image to the screen
    self.slider.minValue = MIN(self.preview.frame.size.width / self.preview.imageSize.width,
                               self.preview.frame.size.height / self.preview.imageSize.height);
  }
}

- (void)windowWillClose:(NSNotification *)notification
{
  [[NSUserDefaults standardUserDefaults] setObject:self.folder.stringValue forKey:@"folder"];
  [[NSUserDefaults standardUserDefaults] setObject:self.scheme.stringValue forKey:@"scheme"];
  [[NSUserDefaults standardUserDefaults] setFloat:self.browser.zoomValue forKey:@"zoom"];
  [[NSUserDefaults standardUserDefaults] synchronize];
}

#pragma mark IKImageBrowserDataSource protocol

- (NSUInteger)numberOfItemsInImageBrowser:(IKImageBrowserView *)browser
{
  return _images.count;
}

- (id)imageBrowser:(IKImageBrowserView *)browser itemAtIndex:(NSUInteger)index
{
	return [_images objectAtIndex:index];
}

- (void) imageBrowser:(IKImageBrowserView *)view removeItemsAtIndexes:(NSIndexSet *)indexes
{
  if (indexes.count == 0)
    return;

  // TODO: This loop is ugly
  NSMutableArray *names = [[NSMutableArray alloc] init];
  for (BrowserItem *image in [_images objectsAtIndexes:indexes]) {
    if (names.count >= 2) {
      break;
    }
    [names addObject:image.name];
  }

  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:@"Delete"];
  [alert addButtonWithTitle:@"Cancel"];
  [alert setMessageText:[NSString stringWithFormat:@"Are you sure you want to delete %@?", [names componentsJoinedByString:@", "]]];
  [alert setInformativeText:@"The images will be removed from disk."];
  [alert setAlertStyle:NSWarningAlertStyle];
  if ([alert runModal] != NSAlertFirstButtonReturn)
    return;

  BOOL success = YES;
  for (BrowserItem *image in [_images objectsAtIndexes:indexes]) {
    success = success && [[NSFileManager defaultManager] removeItemAtPath:image.path error:nil];
  }

  // Setting this to nil will ensure a refresh from disk
  _lastNormalizedPath = nil;
  [self refresh];

  if (success)
    return;

  alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:@"OK"];
  [alert setMessageText:@"Could not delete all images."];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert runModal];
}

#pragma mark Folder navigation

- (IBAction) browseForFolder:(id)sender
{
  NSOpenPanel* panel = [NSOpenPanel openPanel];
  panel.canChooseFiles = NO;
  panel.canChooseDirectories = YES;
  panel.allowsMultipleSelection = NO;

  [panel beginWithCompletionHandler:^(NSInteger result) {
    if (result == NSFileHandlingPanelOKButton) {
      self.folder.stringValue = ((NSURL *)panel.URLs[0]).path;
      [self refresh];
    }
  }];
}

- (IBAction) moveToParentFolder:(id)sender
{
  if (!self.browser.isHidden) {
    self.folder.stringValue = [self.folder.stringValue stringByDeletingLastPathComponent];
    [self refresh];
  } else {
    [self returnToBrowser];
  }
}

- (NSArray *)control:(NSControl *)control textView:(NSTextView *)textView completions:(NSArray *)words
 forPartialWordRange:(NSRange)charRange indexOfSelectedItem:(int*)index
{
  // This seems overly complicated...
  NSMutableArray *completions = [[NSMutableArray alloc] init];

  _images = [[NSMutableArray alloc] init];
  NSString *folder = [self.folder.stringValue stringByDeletingLastPathComponent];
  NSString *partial = self.folder.stringValue.lastPathComponent.lowercaseString;

  // Special case when the user is just getting into a new folder, want to see folders in there
  if ([self.folder.stringValue hasSuffix:@"/"]) {
    folder = self.folder.stringValue;
    partial = @"";
  }

  [completions addObject:[self.folder.stringValue substringFromIndex:charRange.location]];

  if (folder && folder.length > 0) {
    NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:nil];
    for (NSString *name in contents) {
      if ((partial.length == 0 && ![name.lowercaseString hasPrefix:@"."]) ||
          ([name.lowercaseString hasPrefix:partial] && ![name.lowercaseString isEqualToString:partial])) {
        BOOL isFolder = FALSE;
        [[NSFileManager defaultManager] fileExistsAtPath:[folder stringByAppendingPathComponent:name]
                                             isDirectory:&isFolder];
        if (isFolder) {
          if (partial.length > 0) {
            // Because completions happen after space, we need to create the full path,
            // and then subtract that from the full suggestion to get what completion to add
            NSString *fullSuggestion = [folder stringByAppendingPathComponent:name];
            [completions addObject:[fullSuggestion substringFromIndex:charRange.location]];
          } else {
            // When we have the situation when the user typed 'xxx/' (the trailing / being the key)
            // we need to display xxx/<suggestion>
            [completions addObject:[folder.lastPathComponent stringByAppendingPathComponent:name]];
          }
        }
      }
    }
  }
  return completions;
}

#pragma mark File name previewing

- (void)refresh
{
  // Don't refresh if we actually did not switch folders
  if ([_lastNormalizedPath isEqualToString:[self.folder.stringValue stringByStandardizingPath]])
    return;

  // If we are viewing an image, switch back to browsing
  if (self.browser.isHidden)
    [self returnToBrowser];

  // The folder changed, so clear out the timestamp cache
  [_timestampCache removeAllObjects];

  _lastNormalizedPath = [self.folder.stringValue stringByStandardizingPath];

  _images = [[NSMutableArray alloc] init];
  NSString *folder = self.folder.stringValue;

  if (folder && folder.length > 0) {
    BOOL dir;
    [[NSFileManager defaultManager] fileExistsAtPath:folder isDirectory:&dir];
    if (dir) {
      NSArray *contents = [[NSFileManager defaultManager] contentsOfDirectoryAtPath:folder error:nil];
      for (NSString *name in contents) {
        if (![name hasPrefix:@"."]) {
          BrowserItem *image = [[BrowserItem alloc] initWithFolder:folder name:name];
          [_images addObject:image];
        }
      }
    }
  }
  [self generateRenames];
}

- (void) controlTextDidChange:(NSNotification *)notification
{
  if (notification.object == self.folder) {
    [self refresh];
  } else {
    // If we have a lot of images, we don't want to refresh on every key press
    [self.class cancelPreviousPerformRequestsWithTarget:self selector:@selector(generateRenames) object:nil];
    [self performSelector:@selector(generateRenames) withObject:nil afterDelay:1.0];
  }
}

#pragma mark Previewing

- (IBAction)previewOrReturnToBrowser:(id)sender
{
  if (!self.browser.isHidden) {
    NSIndexSet *indexes = self.browser.selectionIndexes;
    if (indexes.count > 0)
      [self imageBrowser:self.browser cellWasDoubleClickedAtIndex:indexes.firstIndex];
  } else {
    [self returnToBrowser];
  }
}

- (void) imageBrowser:(IKImageBrowserView *)browser cellWasDoubleClickedAtIndex:(NSUInteger)index
{
  BrowserItem *image = _images[index];
  if (image.isFolder) {
    self.folder.stringValue = image.path;
    [self refresh];
    return;
  }

  NSURL *url = [NSURL fileURLWithPath:image.path];
  [self.preview setImageWithURL:url];
  [self.preview setCurrentToolMode:IKToolModeMove];

  self.browser.hidden = YES;
  self.preview.hidden = NO;
  [self.window makeFirstResponder:self.preview];

  // I want no animation, but just calling zoomTo ends up showing nothing,
  // calling both disabled the zooming, yet still shows the image. Not sure why.
  [self.preview zoomImageToFit:nil];
  [self zoomTo:0.0];

  // Use the zoom slider for the image, we start out fitted to the window,
  // which becomes the min zoom factor
  self.slider.floatValue = self.preview.zoomFactor;
  self.slider.minValue = self.slider.floatValue;
  self.slider.maxValue = 1.0;

  _previewIndex = index;

  self.previewMenuItemTitle = @"Return to browser";
}

- (IBAction)returnToBrowser
{
  [self.preview setImage:nil imageProperties:nil];

  self.browser.hidden = NO;
  self.preview.hidden = YES;
  [self.window makeFirstResponder:self.browser];
  self.slider.minValue = 0.05;
  self.slider.maxValue = 1.0;
  self.slider.floatValue = self.browser.zoomValue;

  // Ensure that the last image viewed is visible in the browser,
  // since the user could have moved around in the image viewer.
  // Explicitly check, because if the selection is not completely visible,
  // the browser will scroll, which may not really be needed.
  // NOTE: revisit this to check how visible an image is, if it's just
  // a sliver, may wanna scroll it into view.
  NSIndexSet *set = self.browser.visibleItemIndexes;
  if (![set containsIndex:_previewIndex])
    [self.browser scrollIndexToVisible:_previewIndex];

  // There should be some better way to do this. But looks like I can't
  // have two menu items with the same key shortcut, even if only
  // one is visible and enabled at a time.
  self.previewMenuItemTitle = @"View image";
}

- (void)keyDown:(NSEvent *)theEvent
{
  // Probably not needed, but only interested in key presses if we are viewing an image
  if (self.preview.isHidden)
    return;

  unichar firstChar = [[theEvent characters] characterAtIndex: 0];
  if (firstChar != NSDeleteFunctionKey && firstChar != NSDeleteCharFunctionKey && firstChar != NSDeleteCharacter)
    return;

  [self imageBrowser:self.browser removeItemsAtIndexes:[NSIndexSet indexSetWithIndex:_previewIndex]];

  // If there are more images, go into the next one
  if (_previewIndex + 1 < _images.count)
    [self imageBrowser:self.browser cellWasDoubleClickedAtIndex:_previewIndex];

}

- (IBAction)nextImage:(id)sender
{
  [self imageBrowser:self.browser cellWasDoubleClickedAtIndex:(_previewIndex+1) % _images.count];
  [self.browser setSelectionIndexes:[NSIndexSet indexSetWithIndex:_previewIndex] byExtendingSelection:NO];
}

- (IBAction)previousImage:(id)sender
{
  [self imageBrowser:self.browser cellWasDoubleClickedAtIndex:(_previewIndex+_images.count-1) % _images.count];
}

- (void)zoomTo:(float)newZoomFactor
{
  // Use the zoomImageToRect function instead of setting the zoomFactor directly,
  // because that will zoom to the bottom left corner and add a weird zoom in animation.
  // zoomImageToRect zooms in towards the middle.

  // Constrain the zoom factor within the factor that fits the image to the view and 1.0
  float minZoomFactor = MIN(self.preview.frame.size.width / self.preview.imageSize.width,
                            self.preview.frame.size.height / self.preview.imageSize.height);
  float desiredZoomFactor = MIN(MAX(newZoomFactor, minZoomFactor), 1.0);

  [self.preview zoomImageToRect:NSMakeRect(0, 0,
                                           self.preview.frame.size.width / desiredZoomFactor,
                                           self.preview.frame.size.height / desiredZoomFactor)];
  self.slider.floatValue = desiredZoomFactor;
}

- (IBAction)zoomToFit:(id)sender
{
  [self.preview zoomImageToFit:self];
}

- (IBAction)zoomToActualSize:(id)sender
{
  // Use this instead of zoomToActualSize to not zoom into the corner
  [self zoomTo:1.0];
}

#pragma mark Common zooming for browsing and previewing

- (IBAction)zoom:(id)sender
{
  if (!self.browser.isHidden) {
    [self.browser setZoomValue:[sender floatValue]];
    [self.browser setNeedsDisplay:YES];
  } else {
    [self zoomTo:[sender floatValue]];
  }
}

- (IBAction)zoomIn:(id)sender
{
  if (!self.browser.isHidden) {
    self.slider.floatValue += 0.2;
    [self.browser setZoomValue:self.slider.floatValue];
    [self.browser setNeedsDisplay:YES];
  } else {
    [self zoomTo:self.preview.zoomFactor * 1.414214];
  }
}

- (IBAction)zoomOut:(id)sender
{
  if (!self.browser.isHidden) {
    self.slider.floatValue -= 0.2;
    [self.browser setZoomValue:self.slider.floatValue];
    [self.browser setNeedsDisplay:YES];
  } else {
    [self zoomTo:self.preview.zoomFactor / 1.414214];
  }
}

#pragma mark Renaming

- (void)generateRenames
{
  BOOL error = NO;

  // This could be written nicer... And possibly moved to a background thread
  // First we need to get a count of the number of duplicates
  NSMutableDictionary *renames = [[NSMutableDictionary alloc] init];
  for (BrowserItem *image in _images) {
    NSString *rename = [self transform:image.name scheme:self.scheme.stringValue in:image.folder error:&error];
    NSNumber *count = [renames objectForKey:rename];
    if (count == nil) {
      [renames setObject:[NSNumber numberWithInt:1] forKey:rename];
    } else {
      [renames setObject:[NSNumber numberWithInt:count.intValue + 1] forKey:rename];
    }
  }

  // No go through and do the renames
  NSMutableDictionary *counts = [[NSMutableDictionary alloc] init];
  for (BrowserItem *image in _images) {
    NSString *rename = [self transform:image.name scheme:self.scheme.stringValue in:image.folder error:&error];
    NSNumber *count = [renames objectForKey:rename];
    if (count.intValue == 1) {
      image.rename = [self transform:image.name scheme:self.scheme.stringValue in:image.folder error:&error];
    } else {
      // We have multiple images with the same name, need to use the counter
      NSNumber *count = [counts objectForKey:rename];
      if (count == nil)
        count = [NSNumber numberWithInt:1];

      NSString *rename = [self transform:image.name scheme:self.scheme.stringValue in:image.folder error:&error];
      image.rename = [[NSString stringWithFormat:@"%@ %d", [rename stringByDeletingPathExtension], count.intValue]
                      stringByAppendingPathExtension:[rename pathExtension]];
      [counts setObject:[NSNumber numberWithInt:count.intValue + 1] forKey:rename];
    }
  }

  self.schemeError.hidden = !error;
  [self.browser reloadData];
}

- (NSString *)transform:(NSString *)name scheme:(NSString *)scheme in:(NSString *)folder error:(BOOL *)error
{
  // TODO: Could probably use a regex for this
  NSString *path = [folder stringByAppendingPathComponent:name];
  NSDate *time = [_timestampCache objectForKey:path];

  if (time == nil) {
    NSDictionary* attr = [[NSFileManager defaultManager] attributesOfItemAtPath:path error:nil];
    time = [attr fileModificationDate];
    [_timestampCache setObject:time forKey:path];
  }

  *error = NO;

  // First pass is only to figure out the new date
  for (int i = 0; i < scheme.length; ++i)
  {
    if ([scheme characterAtIndex:i] != '[')
      continue;

    // Step over beginning bracket
    ++i;

    // No end? Then it's a bad code
    NSRange range = [scheme rangeOfString:@"]" options:NSLiteralSearch range:NSMakeRange(i, scheme.length - i)];
    if (range.location == NSNotFound) {
      *error = YES;
      break;
    }

    // End bracket comes right after opening, then do nothing?
    if (i == range.location) {
      *error = YES;
      continue;
    }

    // Get the code, and step over the transform
    NSString *code = [scheme substringWithRange:NSMakeRange(i, range.location - i)];
    i = (int)range.location;

    if (![code isEqualToString:@"N"] && ![code isEqualToString:@"E"]) {
      // It should be a datetime code, find out if we have
      // any date time manipulations
      if (code.length >= 3) {
        int offset = [code substringFromIndex:1].intValue;
        NSDateComponents* components = [[NSDateComponents alloc] init];

        if ([code characterAtIndex:0] == 'Y') components.year = offset;
        else if ([code characterAtIndex:0] == 'M') components.month = offset;
        else if ([code characterAtIndex:0] == 'D') components.day = offset;
        else if ([code characterAtIndex:0] == 'h') components.hour = offset;
        else if ([code characterAtIndex:0] == 'm') components.minute = offset;
        else if ([code characterAtIndex:0] == 's') components.second = offset;
        else *error = YES;

        time = [_calendar dateByAddingComponents:components toDate:time options:0];
      }
    }
  }

  NSMutableString *result = [[NSMutableString alloc] init];
  NSDateComponents* components = [_calendar components:
                                  (NSYearCalendarUnit | NSMonthCalendarUnit | NSDayCalendarUnit |
                                   NSHourCalendarUnit | NSMinuteCalendarUnit | NSSecondCalendarUnit) fromDate:time];

  // Now do the actual transform
  for (int i = 0; i < scheme.length; ++i)
  {
    if ([scheme characterAtIndex:i] == '[')
    {
      // Step over beginning bracket
      ++i;

      // No end? Then it's a bad code
      NSRange range = [scheme rangeOfString:@"]" options:NSLiteralSearch range:NSMakeRange(i, scheme.length - i)];
      if (range.location == NSNotFound)
        break;

      // End bracket comes right after opening, then do nothing?
      if (i == range.location)
        continue;

      // Get the code, and step over the transform
      NSString *code = [scheme substringWithRange:NSMakeRange(i, range.location - i)];
      i = (int)range.location;

      if ([code isEqualToString:@"N"]) {
        [result appendString:[name stringByDeletingPathExtension]];
      } else if ([code isEqualToString:@"E"]) {
        [result appendString:[name pathExtension]];
      } else {
        NSInteger val = LONG_MIN;

        if ([code characterAtIndex:0] == 'Y') val = components.year;
        else if ([code characterAtIndex:0] == 'M') val = components.month;
        else if ([code characterAtIndex:0] == 'D') val = components.day;
        else if ([code characterAtIndex:0] == 'h') val = components.hour;
        else if ([code characterAtIndex:0] == 'm') val = components.minute;
        else if ([code characterAtIndex:0] == 's') val = components.second;
        else *error = YES;

        if (val != LONG_MIN)
          [result appendFormat:@"%02ld", val];
      }
    }
    else {
      [result appendString:[scheme substringWithRange:NSMakeRange(i, 1)]];
    }
  }

  return result.length ? result : name;
}

- (IBAction)rename:(id)sender
{
  NSIndexSet *indexes = self.browser.selectionIndexes;

  NSMutableArray *names = [[NSMutableArray alloc] init];
  for (BrowserItem *image in [_images objectsAtIndexes:indexes])
    [names addObject:image.name];

  NSAlert *alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:@"Rename"];
  [alert addButtonWithTitle:@"Cancel"];
  [alert setMessageText:[NSString stringWithFormat:@"Are you sure you want to rename %@?", [names componentsJoinedByString:@","]]];
  [alert setInformativeText:@"The images will be renamed."];
  [alert setAlertStyle:NSWarningAlertStyle];
  if ([alert runModal] != NSAlertFirstButtonReturn)
    return;

  BOOL success = YES;
  for (BrowserItem *image in [_images objectsAtIndexes:indexes]) {
    success = success && [[NSFileManager defaultManager] moveItemAtPath:image.path
                                                                 toPath:[image.folder stringByAppendingPathComponent:image.rename] error:nil];
  }

  // Setting this to nil will ensure a refresh from disk
  _lastNormalizedPath = nil;
  [self refresh];

  if (success)
    return;

  alert = [[NSAlert alloc] init];
  [alert addButtonWithTitle:@"OK"];
  [alert setMessageText:@"Could not rename all images."];
  [alert setAlertStyle:NSWarningAlertStyle];
  [alert runModal];
}

@end
