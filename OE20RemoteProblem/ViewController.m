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
    AVSpeechSynthesizer *synth;
}
@synthesize openEarsEventsObserver;
@synthesize player;

- (OEEventsObserver *)openEarsEventsObserver {
    if (openEarsEventsObserver == nil) {
        openEarsEventsObserver = [[OEEventsObserver alloc] init];
    }
    return openEarsEventsObserver;
}

- (OEPocketsphinxController *)pocketsphinxController {
    if (_pocketsphinxController == nil) {
        _pocketsphinxController = [OEPocketsphinxController sharedInstance];
        [_pocketsphinxController setActive:true error:nil];
    }
    
    
    return _pocketsphinxController;
}


- (BOOL) canBecomeFirstResponder
{
    return YES;
}

- (void)viewDidLoad {
    [super viewDidLoad];
    synth = [[AVSpeechSynthesizer alloc] init];
    [self.openEarsEventsObserver setDelegate:self];
    [[AVAudioSession sharedInstance] setMode:AVAudioSessionModeVideoChat error:nil];
    NSURL *intro = [[NSBundle mainBundle] URLForResource:@"RCCallerIntro" withExtension:@"mp3"];
    player = [[AVPlayer alloc] initWithURL:intro];
    
    /*  Kicking off playback takes over
     *  the software based remote control
     *  interface in the lock screen and
     *  in Control Center.
     */
    
    [player play];
    [[UIApplication sharedApplication] beginReceivingRemoteControlEvents];
    [self resignFirstResponder];
    [self becomeFirstResponder];

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
        [self.pocketsphinxController verbosePocketSphinx];
    }
    NSLog(@"startListening lmPath=%@, dicPath=%@, amPath=%@", lmPath,dicPath,[OEAcousticModel pathToModel:@"AcousticModelEnglish"]);
    [self.pocketsphinxController startListeningWithLanguageModelAtPath:lmPath dictionaryAtPath:dicPath acousticModelAtPath:[OEAcousticModel pathToModel:@"AcousticModelEnglish"] languageModelIsJSGF:NO];
    [self speak:@"Listening for voice commands, you can say: START CALLING, NEXT, PREVIOUS, REPEAT THAT, or STOP CALLING"];
    NSLog(@"Started listening");
}

-(void)speak:(NSString *)toSpeak
{
    [self speak:toSpeak withVoice:[AVSpeechSynthesisVoice voiceWithLanguage:@"en-US"]];
}

-(void)speak:(NSString *)toSpeak withVoice:(AVSpeechSynthesisVoice *)voice
{
    AVSpeechUtterance *utterance;
    if ([toSpeak characterAtIndex:0] == '0') {
        utterance = [AVSpeechUtterance speechUtteranceWithString:[toSpeak substringFromIndex:1]];
    } else {
        utterance = [AVSpeechUtterance speechUtteranceWithString:toSpeak];
    }
    utterance.voice = (voice == nil) ? [AVSpeechSynthesisVoice voiceWithLanguage:[AVSpeechSynthesisVoice currentLanguageCode]] : voice;
    utterance.rate = 0.25 * AVSpeechUtteranceDefaultSpeechRate;
    [synth speakUtterance:utterance];
}


- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
    // Dispose of any resources that can be recreated.
}

- (IBAction)voiceRecognitionChanged:(id)sender {
    if ([self.voiceRecognitionSwitch isOn]) {
        [self initRecognizer];
    } else {
        [self.pocketsphinxController stopListening];
    }
}

- (void) pocketsphinxDidReceiveHypothesis:		(NSString *) 	hypothesis
                         recognitionScore:		(NSString *) 	recognitionScore
                              utteranceID:		(NSString *) 	utteranceID
{
    [self becomeFirstResponder];
    int score = recognitionScore.intValue;
    NSLog(@"Word: %@, Recognition score: %@, utteranceID: %@", hypothesis, recognitionScore, utteranceID);
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
