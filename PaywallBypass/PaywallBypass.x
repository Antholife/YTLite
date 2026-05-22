#import <Foundation/Foundation.h>
#import <UIKit/UIKit.h>
#import <objc/runtime.h>
#import <objc/message.h>

static NSString *const kAntholifeCredit = @"bypass by Antholife";
static NSString *const kAntholifeUnlocked = @"YouTube Plus unlocked — bypass by Antholife";

static BOOL YTLiteBundle(NSBundle *bundle) {
    NSString *path = bundle.bundlePath;
    return path.length > 0 && [path rangeOfString:@"YTLite.bundle"].location != NSNotFound;
}

static BOOL YTLiteKeyHasCredit(NSString *key) {
    if (!key.length) return NO;
    if ([key isEqualToString:@"BuildByAntholife"]) return YES;
    if ([key hasPrefix:@"Welcome."]) return YES;
    if ([key hasPrefix:@"Conflicts."]) return YES;
    static NSSet *extra;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        extra = [NSSet setWithArray:@[
            @"DonationReminder",
            @"SupportDevelopmentDesc",
            @"Contributors",
            @"Credits",
            @"DevContribution",
            @"VisitGithubDesc",
            @"RetryLogin",
            @"LogOutMessage"
        ]];
    });
    return [extra containsObject:key];
}

static NSString *YTLiteApplyCredit(NSString *key, NSString *text) {
    if ([key isEqualToString:@"BuildByAntholife"])
        return kAntholifeCredit;
    if ([key isEqualToString:@"FeaturesNotActivated"])
        return kAntholifeUnlocked;
    if (!text.length)
        return kAntholifeCredit;
    if ([text rangeOfString:@"Antholife" options:NSCaseInsensitiveSearch].location != NSNotFound)
        return text;
    if ([key hasPrefix:@"Welcome."] && ([key hasSuffix:@"Desc"] || [key isEqualToString:@"Welcome.More"]))
        return [NSString stringWithFormat:@"%@\n\n%@", text, kAntholifeCredit];
    return [NSString stringWithFormat:@"%@ · %@", text, kAntholifeCredit];
}

static void YTLiteShowLaunchToast(void) {
    Class toastClass = objc_getClass("YTToastResponderEvent");
    if (!toastClass) return;

    SEL factory = NSSelectorFromString(@"eventWithMessage:firstResponder:");
    if (![toastClass respondsToSelector:factory]) return;

    NSString *message = [NSString stringWithFormat:@"YouTube Plus · %@", kAntholifeCredit];
    id event = ((id (*)(id, SEL, id, id))objc_msgSend)(toastClass, factory, message, nil);
    if (event && [event respondsToSelector:@selector(send)])
        ((void (*)(id, SEL))objc_msgSend)(event, @selector(send));
}

static BOOL YTLiteBypass_isAuthorized(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
    return YES;
}

static void YTLiteBypass_install(void) {
    unsigned int count = 0;
    Class *classes = objc_copyClassList(&count);
    if (!classes) return;

    SEL sel = @selector(isAuthorized);
    for (unsigned int i = 0; i < count; i++) {
        Method m = class_getInstanceMethod(classes[i], sel);
        if (m) method_setImplementation(m, (IMP)YTLiteBypass_isAuthorized);
    }

    free(classes);
}

%hook NSBundle

- (NSString *)localizedStringForKey:(NSString *)key value:(NSString *)value table:(NSString *)tableName {
    if (!YTLiteBundle(self) || !key.length)
        return %orig;

    if ([key isEqualToString:@"BuildByAntholife"])
        return kAntholifeCredit;

    if ([key isEqualToString:@"FeaturesNotActivated"])
        return kAntholifeUnlocked;

    if ([key isEqualToString:@"Log-inViaPatreon"])
        return kAntholifeCredit;

    NSString *result = %orig;
    if (YTLiteKeyHasCredit(key))
        return YTLiteApplyCredit(key, result);

    return result;
}

%end

%ctor {
    YTLiteBypass_install();
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(2 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        YTLiteBypass_install();
    });
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(4 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        YTLiteShowLaunchToast();
    });
}
