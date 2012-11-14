//
//  Copyright (c) 2012-2013 Gandalf Hernandez. All rights reserved.
//


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
