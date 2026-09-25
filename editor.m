#import <Cocoa/Cocoa.h>
#import "editor.h"

@class VZAppDelegate;

@interface VZTextView : NSTextView
@property(nonatomic, weak) VZAppDelegate *vzDelegate;
@end

@interface VZAppDelegate : NSObject <NSApplicationDelegate, NSTextViewDelegate, NSWindowDelegate>
@property(nonatomic, strong) NSWindow *window;
@property(nonatomic, strong) VZTextView *editor;
@property(nonatomic, strong) NSTextField *status;
@property(nonatomic, strong) NSTextField *pathLabel;
@property(nonatomic, strong) NSURL *fileURL;
@property(nonatomic, assign) BOOL dirty;
- (void)newDocument:(id)sender;
- (void)openDocument:(id)sender;
- (void)saveDocument:(id)sender;
- (void)saveDocumentAs:(id)sender;
- (void)findText:(id)sender;
- (void)findNext:(id)sender;
- (void)goToLine:(id)sender;
- (void)openTerminal:(id)sender;
- (void)insertSmartNewline;
- (void)insertIndent;
- (void)updateStatus;
@end

@implementation VZTextView
- (void)keyDown:(NSEvent *)event {
    if (event.keyCode == 36 || event.keyCode == 76) { [self.vzDelegate insertSmartNewline]; return; }
    if (event.keyCode == 48 && !(event.modifierFlags & (NSEventModifierFlagCommand | NSEventModifierFlagControl | NSEventModifierFlagOption))) {
        [self.vzDelegate insertIndent]; return;
    }
    if (event.keyCode == 120) { [self.vzDelegate saveDocument:self]; return; }       // F2
    if (event.keyCode == 99)  { [self.vzDelegate openDocument:self]; return; }       // F3
    if (event.keyCode == 96)  { [self.vzDelegate findText:self]; return; }           // F5
    if (event.keyCode == 97)  { [self.vzDelegate goToLine:self]; return; }           // F6
    if (event.keyCode == 98)  { [self.vzDelegate findNext:self]; return; }            // F7
    if (event.keyCode == 100) { [self.vzDelegate openTerminal:self]; return; }         // F8
    [super keyDown:event];
}
@end

@implementation VZAppDelegate {
    NSString *_lastSearch;
}

- (NSColor *)navy { return [NSColor colorWithSRGBRed:0.025 green:0.075 blue:0.19 alpha:1]; }
- (NSColor *)cyan { return [NSColor colorWithSRGBRed:0.30 green:0.92 blue:0.95 alpha:1]; }
- (NSFont *)mono:(CGFloat)size { return [NSFont monospacedSystemFontOfSize:size weight:NSFontWeightRegular]; }

- (void)applicationDidFinishLaunching:(NSNotification *)note {
    [self buildMenus];
    [self buildWindow];
    [self newDocument:nil];
    [self.window makeKeyAndOrderFront:nil];
    [NSApp activateIgnoringOtherApps:YES];
}

- (BOOL)applicationShouldTerminateAfterLastWindowClosed:(NSApplication *)sender { return YES; }

- (void)buildWindow {
    NSRect frame = NSMakeRect(0, 0, 1024, 720);
    self.window = [[NSWindow alloc] initWithContentRect:frame
                                              styleMask:NSWindowStyleMaskTitled | NSWindowStyleMaskClosable |
                                                        NSWindowStyleMaskMiniaturizable | NSWindowStyleMaskResizable
                                                backing:NSBackingStoreBuffered defer:NO];
    self.window.title = @"VZ Go Editor";
    self.window.minSize = NSMakeSize(640, 420);
    self.window.delegate = self;
    [self.window center];

    NSView *root = self.window.contentView;
    root.wantsLayer = YES;
    root.layer.backgroundColor = self.navy.CGColor;

    self.pathLabel = [NSTextField labelWithString:@""];
    self.pathLabel.translatesAutoresizingMaskIntoConstraints = NO;
    self.pathLabel.font = [self mono:12];
    self.pathLabel.textColor = self.cyan;
    self.pathLabel.backgroundColor = self.navy;
    self.pathLabel.drawsBackground = YES;
    self.pathLabel.lineBreakMode = NSLineBreakByTruncatingMiddle;

    NSScrollView *scroll = [[NSScrollView alloc] initWithFrame:NSZeroRect];
    scroll.translatesAutoresizingMaskIntoConstraints = NO;
    scroll.hasVerticalScroller = YES;
    scroll.hasHorizontalScroller = YES;
    scroll.autohidesScrollers = YES;
    scroll.borderType = NSNoBorder;

    self.editor = [[VZTextView alloc] initWithFrame:NSMakeRect(0, 0, 900, 600)];
    self.editor.vzDelegate = self;
    self.editor.delegate = self;
    self.editor.font = [self mono:15];
    self.editor.backgroundColor = [NSColor colorWithSRGBRed:0.02 green:0.035 blue:0.08 alpha:1];
    self.editor.textColor = [NSColor colorWithSRGBRed:0.88 green:0.92 blue:0.95 alpha:1];
    self.editor.insertionPointColor = self.cyan;
    self.editor.selectedTextAttributes = @{NSBackgroundColorAttributeName: self.cyan,
                                           NSForegroundColorAttributeName: self.navy};
    self.editor.automaticQuoteSubstitutionEnabled = NO;
    self.editor.automaticDashSubstitutionEnabled = NO;
    self.editor.automaticTextReplacementEnabled = NO;
    self.editor.richText = NO;
    self.editor.usesFindBar = YES;
    self.editor.usesFontPanel = NO;
    self.editor.allowsUndo = YES;
    self.editor.textContainer.widthTracksTextView = NO;
    self.editor.textContainer.containerSize = NSMakeSize(CGFLOAT_MAX, CGFLOAT_MAX);
    scroll.documentView = self.editor;

    self.status = [NSTextField labelWithString:@""];
    self.status.translatesAutoresizingMaskIntoConstraints = NO;
    self.status.font = [self mono:12];
    self.status.textColor = self.navy;
    self.status.backgroundColor = self.cyan;
    self.status.drawsBackground = YES;
    self.status.alignment = NSTextAlignmentRight;

    NSTextField *keys = [NSTextField labelWithString:@" F2 保存   F3 開く   F5 検索   F6 行指定   F7 次検索   F8 Terminal "];
    keys.translatesAutoresizingMaskIntoConstraints = NO;
    keys.font = [self mono:12];
    keys.textColor = self.cyan;
    keys.backgroundColor = self.navy;
    keys.drawsBackground = YES;

    [root addSubview:self.pathLabel];
    [root addSubview:scroll];
    [root addSubview:keys];
    [root addSubview:self.status];

    [NSLayoutConstraint activateConstraints:@[
        [self.pathLabel.topAnchor constraintEqualToAnchor:root.topAnchor constant:6],
        [self.pathLabel.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:10],
        [self.pathLabel.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-10],
        [self.pathLabel.heightAnchor constraintEqualToConstant:22],
        [scroll.topAnchor constraintEqualToAnchor:self.pathLabel.bottomAnchor constant:4],
        [scroll.leadingAnchor constraintEqualToAnchor:root.leadingAnchor constant:8],
        [scroll.trailingAnchor constraintEqualToAnchor:root.trailingAnchor constant:-8],
        [scroll.bottomAnchor constraintEqualToAnchor:keys.topAnchor constant:-4],
        [keys.leadingAnchor constraintEqualToAnchor:root.leadingAnchor],
        [keys.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],
        [keys.heightAnchor constraintEqualToConstant:25],
        [self.status.trailingAnchor constraintEqualToAnchor:root.trailingAnchor],
        [self.status.bottomAnchor constraintEqualToAnchor:root.bottomAnchor],
        [self.status.heightAnchor constraintEqualToConstant:25],
        [self.status.widthAnchor constraintGreaterThanOrEqualToConstant:210]
    ]];
}

- (NSMenuItem *)item:(NSString *)title action:(SEL)action key:(NSString *)key modifiers:(NSEventModifierFlags)mods {
    NSMenuItem *item = [[NSMenuItem alloc] initWithTitle:title action:action keyEquivalent:key];
    item.target = self;
    item.keyEquivalentModifierMask = mods;
    return item;
}

- (void)buildMenus {
    NSMenu *bar = [[NSMenu alloc] init];
    NSMenuItem *appRoot = [[NSMenuItem alloc] init];
    NSMenu *app = [[NSMenu alloc] initWithTitle:@"VZ Go Editor"];
    [app addItemWithTitle:@"VZ Go Editorについて" action:@selector(orderFrontStandardAboutPanel:) keyEquivalent:@""];
    [app addItem:[NSMenuItem separatorItem]];
    [app addItemWithTitle:@"終了" action:@selector(terminate:) keyEquivalent:@"q"];
    appRoot.submenu = app; [bar addItem:appRoot];

    NSMenuItem *fileRoot = [[NSMenuItem alloc] init];
    NSMenu *file = [[NSMenu alloc] initWithTitle:@"ファイル"];
    [file addItem:[self item:@"新規" action:@selector(newDocument:) key:@"n" modifiers:NSEventModifierFlagCommand]];
    [file addItem:[self item:@"開く…" action:@selector(openDocument:) key:@"o" modifiers:NSEventModifierFlagCommand]];
    [file addItem:[self item:@"保存" action:@selector(saveDocument:) key:@"s" modifiers:NSEventModifierFlagCommand]];
    [file addItem:[self item:@"別名で保存…" action:@selector(saveDocumentAs:) key:@"S" modifiers:NSEventModifierFlagCommand|NSEventModifierFlagShift]];
    fileRoot.submenu = file; [bar addItem:fileRoot];

    NSMenuItem *editRoot = [[NSMenuItem alloc] init];
    NSMenu *edit = [[NSMenu alloc] initWithTitle:@"編集"];
    [edit addItemWithTitle:@"取り消す" action:@selector(undo:) keyEquivalent:@"z"];
    [edit addItemWithTitle:@"やり直す" action:@selector(redo:) keyEquivalent:@"Z"];
    [edit addItem:[NSMenuItem separatorItem]];
    [edit addItemWithTitle:@"カット" action:@selector(cut:) keyEquivalent:@"x"];
    [edit addItemWithTitle:@"コピー" action:@selector(copy:) keyEquivalent:@"c"];
    [edit addItemWithTitle:@"ペースト" action:@selector(paste:) keyEquivalent:@"v"];
    [edit addItemWithTitle:@"すべて選択" action:@selector(selectAll:) keyEquivalent:@"a"];
    editRoot.submenu = edit; [bar addItem:editRoot];

    NSMenuItem *searchRoot = [[NSMenuItem alloc] init];
    NSMenu *search = [[NSMenu alloc] initWithTitle:@"検索"];
    [search addItem:[self item:@"検索…" action:@selector(findText:) key:@"f" modifiers:NSEventModifierFlagCommand]];
    [search addItem:[self item:@"次を検索" action:@selector(findNext:) key:@"g" modifiers:NSEventModifierFlagCommand]];
    [search addItem:[self item:@"指定行へ…" action:@selector(goToLine:) key:@"l" modifiers:NSEventModifierFlagCommand]];
    searchRoot.submenu = search; [bar addItem:searchRoot];

    NSMenuItem *toolRoot = [[NSMenuItem alloc] init];
    NSMenu *tool = [[NSMenu alloc] initWithTitle:@"ツール"];
    [tool addItem:[self item:@"この場所をターミナルで開く" action:@selector(openTerminal:) key:@"T" modifiers:NSEventModifierFlagCommand|NSEventModifierFlagShift]];
    toolRoot.submenu = tool; [bar addItem:toolRoot];
    NSApp.mainMenu = bar;
}

- (NSAlert *)prompt:(NSString *)title message:(NSString *)message fields:(NSArray<NSString *> *)labels {
    NSAlert *alert = [[NSAlert alloc] init];
    alert.messageText = title;
    alert.informativeText = message;
    [alert addButtonWithTitle:@"実行"];
    [alert addButtonWithTitle:@"キャンセル"];
    CGFloat y = 0;
    NSView *box = [[NSView alloc] initWithFrame:NSMakeRect(0, 0, 360, labels.count * 48)];
    for (NSUInteger i = 0; i < labels.count; i++) {
        NSTextField *label = [NSTextField labelWithString:labels[i]];
        label.frame = NSMakeRect(0, labels.count * 48 - 24 - y, 90, 22);
        NSTextField *field = [[NSTextField alloc] initWithFrame:NSMakeRect(95, labels.count * 48 - 28 - y, 255, 26)];
        field.tag = (NSInteger)i + 1;
        [box addSubview:label]; [box addSubview:field]; y += 48;
    }
    alert.accessoryView = box;
    return alert;
}

- (BOOL)confirmDiscard {
    if (!self.dirty) return YES;
    NSAlert *a = [[NSAlert alloc] init];
    a.messageText = @"未保存の変更があります";
    a.informativeText = @"変更を破棄して続けますか？";
    [a addButtonWithTitle:@"キャンセル"];
    [a addButtonWithTitle:@"破棄"];
    return [a runModal] == NSAlertSecondButtonReturn;
}

- (void)newDocument:(id)sender {
    if (![self confirmDiscard]) return;
    self.fileURL = nil; self.editor.string = @""; self.dirty = NO;
    [self refreshTitle]; [self updateStatus];
}

- (void)openDocument:(id)sender {
    if (![self confirmDiscard]) return;
    NSOpenPanel *panel = [NSOpenPanel openPanel];
    panel.canChooseDirectories = NO; panel.allowsMultipleSelection = NO;
    if ([panel runModal] != NSModalResponseOK) return;
    NSError *error = nil;
    NSString *text = [NSString stringWithContentsOfURL:panel.URL encoding:NSUTF8StringEncoding error:&error];
    if (!text) { [self showError:error.localizedDescription]; return; }
    self.fileURL = panel.URL; self.editor.string = text; self.dirty = NO;
    [self refreshTitle]; [self updateStatus];
}

- (void)saveDocument:(id)sender {
    if (!self.fileURL) { [self saveDocumentAs:sender]; return; }
    NSError *error = nil;
    if (![self.editor.string writeToURL:self.fileURL atomically:YES encoding:NSUTF8StringEncoding error:&error]) {
        [self showError:error.localizedDescription]; return;
    }
    self.dirty = NO; [self refreshTitle];
}

- (void)saveDocumentAs:(id)sender {
    NSSavePanel *panel = [NSSavePanel savePanel];
    panel.nameFieldStringValue = self.fileURL.lastPathComponent ?: @"untitled.txt";
    if ([panel runModal] != NSModalResponseOK) return;
    self.fileURL = panel.URL; [self saveDocument:sender];
}

- (void)findText:(id)sender {
    NSAlert *a = [self prompt:@"検索" message:@"検索する文字列を入力してください。" fields:@[@"検索文字列"]];
    if ([a runModal] != NSAlertFirstButtonReturn) return;
    _lastSearch = [(NSTextField *)[a.accessoryView viewWithTag:1] stringValue];
    [self findNext:nil];
}

- (void)findNext:(id)sender {
    if (_lastSearch.length == 0) { [self findText:sender]; return; }
    NSString *source = self.editor.string;
    NSUInteger start = NSMaxRange(self.editor.selectedRange);
    NSRange range = [source rangeOfString:_lastSearch options:0 range:NSMakeRange(start, source.length - start)];
    if (range.location == NSNotFound && start > 0) range = [source rangeOfString:_lastSearch];
    if (range.location == NSNotFound) { NSBeep(); return; }
    [self.editor setSelectedRange:range]; [self.editor scrollRangeToVisible:range]; [self updateStatus];
}

- (void)goToLine:(id)sender {
    NSAlert *a = [self prompt:@"指定行へ" message:@"移動先の行番号を入力してください。" fields:@[@"行番号"]];
    if ([a runModal] != NSAlertFirstButtonReturn) return;
    NSInteger target = [(NSTextField *)[a.accessoryView viewWithTag:1] integerValue];
    if (target < 1) return;
    __block NSInteger line = 1; __block NSUInteger pos = 0;
    [self.editor.string enumerateSubstringsInRange:NSMakeRange(0, self.editor.string.length)
                                           options:NSStringEnumerationByLines | NSStringEnumerationSubstringNotRequired
                                        usingBlock:^(NSString *s, NSRange r, NSRange e, BOOL *stop) {
        if (line == target) { pos = r.location; *stop = YES; } line++;
    }];
    [self.editor setSelectedRange:NSMakeRange(pos, 0)]; [self.editor scrollRangeToVisible:NSMakeRange(pos, 0)]; [self updateStatus];
}

- (void)openTerminal:(id)sender {
    NSURL *directory = self.fileURL ? [self.fileURL URLByDeletingLastPathComponent]
                                    : [NSURL fileURLWithPath:NSHomeDirectory() isDirectory:YES];
    NSTask *task = [[NSTask alloc] init];
    task.launchPath = @"/usr/bin/open";
    task.arguments = @[@"-a", @"Terminal", directory.path];
    @try { [task launch]; }
    @catch (NSException *exception) { [self showError:exception.reason]; }
}

- (NSString *)indentUnit {
    NSString *ext = self.fileURL.pathExtension.lowercaseString ?: @"";
    NSSet *twoSpaces = [NSSet setWithArray:@[@"js", @"jsx", @"ts", @"tsx", @"json", @"html", @"htm", @"css", @"scss", @"vue", @"svelte", @"rb", @"sh", @"yaml", @"yml"]];
    NSSet *fourSpaces = [NSSet setWithArray:@[@"py", @"c", @"h", @"cc", @"cpp", @"hpp", @"m", @"mm", @"java", @"cs", @"rs", @"swift", @"kt", @"kts"]];
    if ([ext isEqualToString:@"go"]) return @"\t";
    if ([twoSpaces containsObject:ext]) return @"  ";
    if ([fourSpaces containsObject:ext]) return @"    ";
    return @"    ";
}

- (BOOL)lineOpensBlock:(NSString *)trimmed {
    if ([trimmed hasSuffix:@"{"] || [trimmed hasSuffix:@"("] || [trimmed hasSuffix:@"["]) return YES;
    NSString *ext = self.fileURL.pathExtension.lowercaseString ?: @"";
    if ([ext isEqualToString:@"py"] || [ext isEqualToString:@"yaml"] || [ext isEqualToString:@"yml"]) {
        return [trimmed hasSuffix:@":"];
    }
    if ([ext isEqualToString:@"rb"] || [ext isEqualToString:@"sh"]) {
        NSArray *words = @[@" do", @" then", @" case", @" begin"];
        for (NSString *word in words) if ([trimmed hasSuffix:word] || [trimmed isEqualToString:[word substringFromIndex:1]]) return YES;
    }
    if ([ext isEqualToString:@"html"] || [ext isEqualToString:@"htm"] || [ext isEqualToString:@"xml"]) {
        return [trimmed hasSuffix:@">"] && ![trimmed hasSuffix:@"/>"] && ![trimmed hasPrefix:@"</"] && ![trimmed hasPrefix:@"<!"];
    }
    return NO;
}

- (void)insertSmartNewline {
    NSString *text = self.editor.string ?: @"";
    NSRange selection = self.editor.selectedRange;
    NSUInteger cursor = MIN(selection.location, text.length);
    NSRange lineRange = [text lineRangeForRange:NSMakeRange(cursor, 0)];
    NSUInteger beforeLength = cursor - lineRange.location;
    NSString *before = [text substringWithRange:NSMakeRange(lineRange.location, beforeLength)];

    NSCharacterSet *notWhitespace = [[NSCharacterSet whitespaceCharacterSet] invertedSet];
    NSRange firstText = [before rangeOfCharacterFromSet:notWhitespace];
    NSString *leading = firstText.location == NSNotFound ? before : [before substringToIndex:firstText.location];
    NSString *trimmed = [before stringByTrimmingCharactersInSet:[NSCharacterSet whitespaceCharacterSet]];
    NSString *extra = [self lineOpensBlock:trimmed] ? [self indentUnit] : @"";

    NSString *insertion = [NSString stringWithFormat:@"\n%@%@", leading, extra];
    [self.editor insertText:insertion replacementRange:selection];
}

- (void)insertIndent {
    [self.editor insertText:[self indentUnit] replacementRange:self.editor.selectedRange];
}

- (void)textDidChange:(NSNotification *)notification { self.dirty = YES; [self refreshTitle]; [self updateStatus]; }
- (void)textViewDidChangeSelection:(NSNotification *)notification { [self updateStatus]; }

- (void)refreshTitle {
    NSString *name = self.fileURL.lastPathComponent ?: @"無題";
    self.window.title = [NSString stringWithFormat:@"%@%@ — VZ Go Editor", self.dirty ? @"● " : @"", name];
    self.pathLabel.stringValue = self.fileURL.path ?: @"[ NEW FILE ]  UTF-8 / LF";
}

- (void)updateStatus {
    NSString *s = self.editor.string ?: @"";
    NSUInteger p = MIN(self.editor.selectedRange.location, s.length), line = 1, col = 1;
    for (NSUInteger i = 0; i < p; i++) { if ([s characterAtIndex:i] == '\n') { line++; col = 1; } else col++; }
    NSUInteger lines = 1;
    for (NSUInteger i = 0; i < s.length; i++) if ([s characterAtIndex:i] == '\n') lines++;
    self.status.stringValue = [NSString stringWithFormat:@" Ln %lu  Col %lu  |  %lu lines  %lu chars ",
                               (unsigned long)line, (unsigned long)col, (unsigned long)lines, (unsigned long)s.length];
}

- (void)showError:(NSString *)message {
    NSAlert *a = [[NSAlert alloc] init]; a.messageText = @"エラー"; a.informativeText = message ?: @"不明なエラー";
    [a addButtonWithTitle:@"OK"]; [a runModal];
}

- (BOOL)windowShouldClose:(NSWindow *)sender { return [self confirmDiscard]; }
@end

void RunVZEditor(void) {
    @autoreleasepool {
        NSApplication *app = [NSApplication sharedApplication];
        app.activationPolicy = NSApplicationActivationPolicyRegular;
        VZAppDelegate *delegate = [[VZAppDelegate alloc] init];
        app.delegate = delegate;
        [app run];
    }
}
