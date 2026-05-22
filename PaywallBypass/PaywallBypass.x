#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString *const kAntholifeCredit = @"bypass by Antholife";
static NSString *const kAntholifeUnlocked = @"YouTube Plus unlocked — bypass by Antholife";

static BOOL YTLiteBundle(NSBundle *bundle) {
    NSString *path = bundle.bundlePath;
    return path.length > 0 && [path rangeOfString:@"YTLite.bundle"].location != NSNotFound;
}

static BOOL YTLiteAuthPrefsKey(NSString *key) {
    if (!key.length) return NO;
    NSString *lower = key.lowercaseString;
    NSArray *needles = @[
        @"patreon", @"authorized", @"authorised", @"activated", @"loggedin",
        @"login", @"subscription", @"member", @"entitled", @"skiplogin"
    ];
    for (NSString *needle in needles) {
        if ([lower containsString:needle]) return YES;
    }
    return NO;
}

static BOOL YTLiteShouldHookAuthClass(const char *name) {
    if (!name || name[0] == '_') return NO;
    if (strstr(name, "Patreon")) return YES;
    if (strstr(name, "YTLite") && strstr(name, "Auth")) return YES;
    if (strstr(name, "YTPlus") && strstr(name, "Auth")) return YES;
    if (strstr(name, "YTL") && strstr(name, "Auth") && !strstr(name, "WebKit")) return YES;
    return NO;
}

static BOOL YTLiteBypass_isAuthorized(id self, SEL _cmd) {
    (void)self;
    (void)_cmd;
    return YES;
}

static void YTLiteBypass_installAuthHooks(void) {
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        unsigned int count = 0;
        Class *classes = objc_copyClassList(&count);
        if (!classes) return;

        SEL sel = @selector(isAuthorized);
        for (unsigned int i = 0; i < count; i++) {
            const char *name = class_getName(classes[i]);
            if (!YTLiteShouldHookAuthClass(name)) continue;

            Method m = class_getInstanceMethod(classes[i], sel);
            if (m) method_setImplementation(m, (IMP)YTLiteBypass_isAuthorized);
        }

        free(classes);
    });
}

static BOOL YTLiteKeyHasCredit(NSString *key) {
    if (!key.length) return NO;
    if ([key isEqualToString:@"BuildByAntholife"]) return YES;
    if ([key hasPrefix:@"Welcome."] && ([key hasSuffix:@"Desc"] || [key isEqualToString:@"Welcome.More"]))
        return YES;
    static NSSet *extra;
    static dispatch_once_t onceToken;
    dispatch_once(&onceToken, ^{
        extra = [NSSet setWithArray:@[@"DonationReminder", @"FeaturesNotActivated"]];
    });
    return [extra containsObject:key];
}

static NSString *YTLiteApplyCredit(NSString *key, NSString *text) {
    if ([key isEqualToString:@"FeaturesNotActivated"])
        return kAntholifeUnlocked;
    if (!text.length)
        return kAntholifeCredit;
    if ([text rangeOfString:@"Antholife" options:NSCaseInsensitiveSearch].location != NSNotFound)
        return text;
    if ([key hasPrefix:@"Welcome."])
        return [NSString stringWithFormat:@"%@\n\n%@", text, kAntholifeCredit];
    return [NSString stringWithFormat:@"%@ · %@", text, kAntholifeCredit];
}

%hook YTLUserDefaults

- (BOOL)boolForKey:(NSString *)key {
    if (YTLiteAuthPrefsKey(key)) return YES;
    return %orig;
}

- (NSInteger)integerForKey:(NSString *)key {
    if (YTLiteAuthPrefsKey(key)) return 1;
    return %orig;
}

%end

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
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        YTLiteBypass_installAuthHooks();
    });
}
