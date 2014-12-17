//
//  ViewController.h
//  OE20RemoteProblem
//
//  Created by Vogel, Peter on 12/15/14.
//  Copyright (c) 2014 Vogel, Peter. All rights reserved.
//

#import <UIKit/UIKit.h>
#import <OpenEars/OEPocketsphinxController.h>
#import <OpenEars/OELanguageModelGenerator.h>
#import <OpenEars/OEEventsObserver.h>

@interface ViewController : UIViewController<OEEventsObserverDelegate>
@property (strong, nonatomic) OEPocketsphinxController *pocketsphinxController;
@property (weak, nonatomic) IBOutlet UISwitch *ToggleSwitch;
@property (weak, nonatomic) IBOutlet UISwitch *voiceRecognitionSwitch;
- (IBAction)voiceRecognitionChanged:(id)sender;

@end

