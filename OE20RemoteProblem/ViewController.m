//
//  ViewController.m
//  OE20RemoteProblem
//
//  Created by Vogel, Peter on 12/15/14.
//  Copyright (c) 2014 Vogel, Peter. All rights reserved.
//

#import "ViewController.h"
#import <OpenEars/OELogging.h>
#import <OpenEars/OEAcousticModel.h>
#import <AVFoundation/AVFoundation.h>
@interface ViewController ()
@property (strong, nonatomic) AVPlayer *player;
@property (strong, nonatomic) OEEventsObserver *openEarsEventsObserver;
@end

@implementation ViewController {
    OELanguageModelGenerator *lmg;
}
@synthesize openEarsEventsObserver;
@synthesize player;
@synthesize Status;


- (BOOL) canBecomeFirstResponder
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    if (openEarsEventsObserver == nil) {
        openEarsEventsObserver = [[OEEventsObserver alloc] init];
    }
    [openEarsEventsObserver setDelegate:self];
    NSURL *intro = [[NSBundle mainBundle] URLForResource:@"RCCallerIntro" withExtension:@"mp3"];
    player = [[AVPlayer alloc] initWithURL:intro];
    
    /*  Kicking off playback lets us start receiving remote control events     */
    [player play];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];

}

- (void)remoteControlReceivedWithEvent:(UIEvent *)event
{
    switch (event.subtype) {
        case UIEventSubtypeRemoteControlPlay:
        case UIEventSubtypeRemoteControlTogglePlayPause:
            [self.ToggleSwitch setOn:![self.ToggleSwitch isOn]];
            break;
        default:
            break;
    }
}

-(void) initRecognizer
{
    //[OpenEarsLogging startOpenEarsLogging];
    NSLog(@"initRecognizer");
    lmg = [[OELanguageModelGenerator alloc] init];
    NSArray *words = [NSArray arrayWithObjects:@"NEXT", @"REPEAT THAT", @"PREVIOUS", @"START CALLING", @"STOP CALLING", nil];
    NSString *name = @"SimpleModel";
    NSError *err = [lmg generateLanguageModelFromArray:words withFilesNamed:name forAcousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"]];
    NSString *dicPath;
    NSString *lmPath;
    
    if([err code] != noErr) {
        NSLog(@"Error: %@",[err localizedDescription]);
    } else {
        dicPath = [lmg pathToSuccessfullyGeneratedDictionaryWithRequestedName:name];
        lmPath = [lmg pathToSuccessfullyGeneratedLanguageModelWithRequestedName:name];
    }
    [[OEPocketsphinxController sharedInstance] startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dicPath acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:NO];
    NSLog(@"Started listening");
    Status.text = @"Started listening";
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)voiceRecognitionChanged:(id)sender {
    if ([self.voiceRecognitionSwitch isOn]) {
        [self initRecognizer];
    } else {
        [[OEPocketsphinxController sharedInstance] stopListening];
        Status.text = @"stopped listening";
    }
}

- (void) pocketsphinxDidReceiveHypothesis:		(NSString *) 	hypothesis
                         recognitionScore:		(NSString *) 	recognitionScore
                              utteranceID:		(NSString *) 	utteranceID
{
    NSLog(@"Word: %@, Recognition score: %@, utteranceID: %@", hypothesis, recognitionScore, utteranceID);
    Status.text = hypothesis;
}

- (void) audioSessionInterruptionDidBegin {
    NSLog(@"Audio session interrupted");
}
/** The interruption ended.*/
- (void) audioSessionInterruptionDidEnd {
    NSLog(@"audio session interruption ended");
}
/** The input became unavailable.*/
- (void) audioInputDidBecomeUnavailable {
    NSLog(@"lost audio input");
}
/** The input became available again.*/
- (void) audioInputDidBecomeAvailable {
    NSLog(@"audio input available");
}

/** The audio route changed.*/
- (void) audioRouteDidChangeToRoute:(NSString *)newRoute {
    NSLog(@"Audio route changed to: %@", newRoute);
}

- (void) pocketSphinxContinuousSetupDidFail { // This can let you know that something went wrong with the recognition loop startup. Turn on OPENEARSLOGGING to learn why.
    NSLog(@"Setting up the continuous recognition loop has failed for some reason, please turn on OpenEarsLogging to learn more.");
}


@end
