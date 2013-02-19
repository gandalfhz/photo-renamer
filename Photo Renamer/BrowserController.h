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

#import <Cocoa/Cocoa.h>
#import <Quartz/Quartz.h>

@interface BrowserController : NSWindowController

- (IBAction)zoom:(id)sender;
- (IBAction)browseForFolder:(id)sender;
- (IBAction)moveToParentFolder:(id)sender;

- (IBAction)returnToBrowser;
- (IBAction)previewOrReturnToBrowser:(id)sender;

- (IBAction)zoomIn:(id)sender;
- (IBAction)zoomOut:(id)sender;
- (IBAction)zoomToFit:(id)sender;
- (IBAction)zoomToActualSize:(id)sender;

- (IBAction)nextImage:(id)sender;
- (IBAction)previousImage:(id)sender;

- (IBAction)rename:(id)sender;

@property (weak) IBOutlet IKImageBrowserView *browser;
@property (weak) IBOutlet NSSlider *slider;
@property (weak) IBOutlet NSTextField *folder;
@property (weak) IBOutlet NSTextField *scheme;
@property (weak) IBOutlet NSTextField *schemeError;
@property (weak) IBOutlet IKImageView *preview;

@property (readonly) NSString *previewMenuItemTitle;

@end
