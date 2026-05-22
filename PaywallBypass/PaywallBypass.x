#import <Foundation/Foundation.h>
#import <objc/runtime.h>

static NSString *const kAntholifeCredit = @"bypass by Antholife";
static NSString *const kAntholifeUnlocked = @"YouTube Plus unlocked — bypass by Antholife";
static NSString *const kAntholifeRepoURL = @"https://github.com/Antholife/YTLite/tree/bypass";

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

static NSString *YB_ItemString(id item, NSString *key) {
    if (!item || !key.length) return nil;
    @try {
        id value = [item valueForKey:key];
        if ([value isKindOfClass:[NSString class]]) return value;
    } @catch (__unused NSException *e) {}
    return nil;
}

static BOOL YB_TextMatches(NSString *text, NSString *needle) {
    if (!text.length || !needle.length) return NO;
    return [text rangeOfString:needle options:NSCaseInsensitiveSearch].location != NSNotFound;
}

static BOOL YB_RowsContainAntholife(NSArray *rows) {
    for (id row in rows) {
        if (YB_TextMatches(YB_ItemString(row, @"title"), @"Antholife")) return YES;
    }
    return NO;
}

static BOOL YB_RowsLookLikeContributors(NSArray *rows) {
    NSUInteger hits = 0;
    for (id row in rows) {
        NSString *title = YB_ItemString(row, @"title");
        if (YB_TextMatches(title, @"Stalker") || YB_TextMatches(title, @"Balackburn") ||
            YB_TextMatches(title, @"SKEIDs") || YB_TextMatches(title, @"Hiepvk") ||
            YB_TextMatches(title, @"Clement") || YB_TextMatches(title, @"Deci8BelioS") ||
            YB_TextMatches(title, @"Dayanch") || YB_TextMatches(title, @"Dan Pashin"))
            hits++;
    }
    return hits >= 2;
}

static BOOL YB_RowsLookLikeDeveloper(NSArray *rows) {
    for (id row in rows) {
        NSString *title = YB_ItemString(row, @"title");
        NSString *desc = YB_ItemString(row, @"titleDescription");
        if (YB_TextMatches(title, @"Github") || YB_TextMatches(title, @"Telegram") ||
            YB_TextMatches(title, @"Follow") || YB_TextMatches(desc, @"Developer") ||
            YB_TextMatches(desc, @"Développeur") || YB_TextMatches(title, @"Dayanch"))
            return YES;
    }
    return NO;
}

static id YB_MakeLinkItem(NSString *title, NSString *desc, NSString *url) {
    Class itemClass = objc_getClass("YTSettingsSectionItem");
    Class uiUtils = objc_getClass("YTUIUtils");
    if (!itemClass || !uiUtils) return nil;

    return [itemClass itemWithTitle:title
        titleDescription:desc
        accessibilityIdentifier:@"YTLiteSectionItem"
        detailTextBlock:nil
        selectBlock:^BOOL(id cell, NSUInteger arg1) {
            (void)cell;
            (void)arg1;
            NSURL *link = [NSURL URLWithString:url];
            return link ? [uiUtils openURL:link] : NO;
        }];
}

static id YB_MakeHeaderItem(NSString *title, NSString *desc) {
    Class itemClass = objc_getClass("YTSettingsSectionItem");
    if (!itemClass) return nil;

    return [itemClass itemWithTitle:title
        titleDescription:desc
        accessibilityIdentifier:@"YTLiteSectionItem"
        detailTextBlock:nil
        selectBlock:^BOOL(id cell, NSUInteger arg1) {
            (void)cell;
            (void)arg1;
            return YES;
        }];
}

static NSArray *YB_InjectContributorsRows(NSArray *rows) {
    if (!rows.count || YB_RowsContainAntholife(rows)) return rows;
    if (!YB_RowsLookLikeContributors(rows)) return rows;

    NSMutableArray *updated = [rows mutableCopy];
    id header = YB_MakeHeaderItem(@"Bypass", kAntholifeCredit);
    id link = YB_MakeLinkItem(@"Antholife", kAntholifeCredit, kAntholifeRepoURL);
    if (link) [updated insertObject:link atIndex:0];
    if (header) [updated insertObject:header atIndex:0];
    return updated;
}

static NSArray *YB_InjectDeveloperRows(NSArray *rows) {
    if (!rows.count || YB_RowsContainAntholife(rows)) return rows;
    if (!YB_RowsLookLikeDeveloper(rows)) return rows;

    NSMutableArray *updated = [rows mutableCopy];
    id link = YB_MakeLinkItem(@"Antholife", kAntholifeCredit, kAntholifeRepoURL);
    if (!link) return rows;

    NSUInteger insertAt = 0;
    for (NSUInteger i = 0; i < updated.count; i++) {
        if (YB_TextMatches(YB_ItemString(updated[i], @"title"), @"Dayanch")) {
            insertAt = i + 1;
            break;
        }
    }
    [updated insertObject:link atIndex:insertAt];
    return updated;
}

static NSString *YB_PickerLabel(id value) {
    return [value isKindOfClass:[NSString class]] ? value : nil;
}

static NSArray *YB_AdjustPickerRows(NSString *navTitle, NSString *sectionTitle, NSArray *rows) {
    NSString *context = [NSString stringWithFormat:@"%@ %@", navTitle ?: @"", sectionTitle ?: @""].lowercaseString;

    if ([context containsString:@"contributor"] || [context containsString:@"credit"] || [context containsString:@"crédit"])
        return YB_InjectContributorsRows(rows);
    if ([context containsString:@"developer"] || [context containsString:@"développeur"])
        return YB_InjectDeveloperRows(rows);

    NSArray *contributors = YB_InjectContributorsRows(rows);
    if (contributors != rows) return contributors;

    return YB_InjectDeveloperRows(rows);
}

%hook YTSettingsPickerViewController

- (instancetype)initWithNavTitle:(id)navTitle pickerSectionTitle:(id)pickerSectionTitle rows:(NSArray *)rows selectedItemIndex:(NSUInteger)selectedItemIndex parentResponder:(id)parentResponder {
    NSArray *updatedRows = YB_AdjustPickerRows(YB_PickerLabel(navTitle), YB_PickerLabel(pickerSectionTitle), rows);
    return %orig(navTitle, pickerSectionTitle, updatedRows, selectedItemIndex, parentResponder);
}

%end

%ctor {
    dispatch_after(dispatch_time(DISPATCH_TIME_NOW, (int64_t)(0.5 * NSEC_PER_SEC)), dispatch_get_main_queue(), ^{
        YTLiteBypass_installAuthHooks();
    });
}
