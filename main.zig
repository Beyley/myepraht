const std = @import("std");
const esc_code = std.ascii.control_code.esc;
const log = std.log;

const chunk_even_color = "[38;2;46;194;126m";
const chunk_odd_color = "[38;2;143;240;164m";
const correct_color = "[38;2;0;243;25m";
const consonant_color = "[38;2;245;194;17m";
const vowel_color = "[38;2;28;113;216m";
const none_color = "[38;2;255;0;0m";

fn writeColor(writer: *std.Io.Writer, color: []const u8) !void {
    try writer.print("{c}{s}", .{ esc_code, color });
}

fn clearFormatting(writer: *std.Io.Writer) !void {
    try writer.print("{c}[0m", .{esc_code});
}

pub const std_options: std.Options = .{};

const Character = enum {
    FRAI,
    FREI,
    KRAI,
    KREI,
    MYAI,
    MYEI,
    NYAI,
    NYEI,
    PRAI,
    PREI,
    PYAI,
    PYEI,
    CAI,
    CEI,
    DAI,
    DEI,
    FAI,
    FEI,
    FRA,
    FRE,
    FRH,
    FRI,
    FRW,
    HAI,
    HEI,
    KAI,
    KEI,
    KRA,
    KRE,
    KRH,
    KRI,
    KRW,
    MAI,
    MEI,
    MYA,
    MYE,
    MYH,
    NAI,
    NEI,
    NYA,
    NYE,
    NYH,
    PAI,
    PEI,
    PRA,
    PRE,
    PRH,
    PRI,
    PRW,
    PYA,
    PYE,
    PYH,
    RAI,
    REI,
    SAI,
    SEI,
    YAI,
    YEI,
    CA,
    CE,
    CH,
    CI,
    CW,
    DA,
    DE,
    DH,
    DI,
    DW,
    FA,
    FE,
    FH,
    FI,
    FW,
    GI,
    GW,
    HA,
    HE,
    HI,
    HW,
    KA,
    KE,
    KH,
    KW,
    MA,
    ME,
    MH,
    MI,
    MW,
    NA,
    NE,
    NH,
    NI,
    NW,
    PA,
    PE,
    PH,
    PI,
    PW,
    RA,
    RE,
    RH,
    RI,
    RW,
    SA,
    SE,
    SH,
    SI,
    SW,
    YA,
    YE,
    YH,
    C,
    D,
    F,
    G,
    H,
    K,
    M,
    N,
    P,
    R,
    S,
    Y,

    pub const Vowel = enum {
        I,
        E,
        A,
        W,
        EI,
        AI,
        H,
    };

    pub const Comparison = union(enum) {
        equal: void,
        same_consonant: void,
        same_vowel: void,
        different: void,
    };

    const OnsetType = enum {
        single,
        with_r,
        with_y,

        pub fn length(self: OnsetType) usize {
            return switch (self) {
                .single => 1,
                .with_r => 2,
                .with_y => 2,
            };
        }
    };

    fn determineOnsetType(char: Character) OnsetType {
        const str = @tagName(char);

        if (str.len == 1) {
            return .single;
        }

        if (str[1] == 'R') {
            return .with_r;
        }

        if (str[1] == 'Y') {
            return .with_y;
        }

        return .single;
    }

    fn determineVowel(char: Character) ?Vowel {
        const str = @tagName(char);

        const vowel_str = str[determineOnsetType(char).length()..];

        if (vowel_str.len == 0) {
            return null;
        }

        return std.meta.stringToEnum(Vowel, vowel_str) orelse std.debug.panic("Unhandled vowel {s}", .{vowel_str});
    }

    pub fn compareWith(lhs: Character, rhs: Character) Comparison {
        if (lhs == rhs) {
            return .equal;
        }

        const lhs_str = @tagName(lhs);
        const rhs_str = @tagName(rhs);

        const lhs_onset = determineOnsetType(lhs);
        const rhs_onset = determineOnsetType(rhs);

        const lhs_vowel = determineVowel(lhs);
        const rhs_vowel = determineVowel(rhs);

        const vowel_same = lhs_vowel != null and lhs_vowel == rhs_vowel;
        const consonant_same = std.mem.eql(u8, lhs_str[0..lhs_onset.length()], rhs_str[0..rhs_onset.length()]);

        if (consonant_same) {
            return .same_consonant;
        }

        if (vowel_same) {
            return .same_vowel;
        }

        return .different;
    }
};

const character_array = std.enums.values(Character);

const num_characters = @typeInfo(Character).@"enum".fields.len;

// Can fit all characters
const Integer = u128;

const Word = struct {
    nahnya: []const u8,
    characters: []const Character,
};

fn trimWhitespace(buf: []u8) []u8 {
    // NOTE: *really?*
    return @constCast(std.mem.trim(u8, buf, &std.ascii.whitespace));
}

fn readInput(reader: *std.io.Reader) !?[]u8 {
    const input = try reader.takeDelimiter('\n');

    return trimWhitespace(input orelse return null);
}

/// Checks how many characters at the start of the input match the word
fn checkStart(buf: []Character.Comparison, word: []const Character, input: []const Character) []Character.Comparison {
    for (input, 0..) |input_character, i| {
        if ((i) >= word.len) {
            return buf[0..i];
        }

        const word_character = word[i];

        const comparison = word_character.compareWith(input_character);

        if (comparison == .different) {
            return buf[0..i];
        }

        buf[i] = comparison;
    }

    return buf[0..input.len];
}

fn checkEnd(gpa: std.mem.Allocator, buf: []Character.Comparison, word: []const Character, input: []const Character) ![]Character.Comparison {
    const reverse_word = try gpa.dupe(Character, word);
    defer gpa.free(reverse_word);
    const reverse_input = try gpa.dupe(Character, input);
    defer gpa.free(reverse_input);

    std.mem.reverse(Character, reverse_word);
    std.mem.reverse(Character, reverse_input);

    const ret = checkStart(buf, reverse_word, reverse_input);
    std.mem.reverse(Character.Comparison, ret);
    return ret;
}

pub fn main() !void {
    const gpa = std.heap.smp_allocator;

    const words_txt = @embedFile("neptunian_word_list.csv");

    var words: std.ArrayListUnmanaged(Word) = .empty;

    var characters: std.ArrayListUnmanaged(Character) = .empty;
    var words_txt_line_iter = std.mem.splitScalar(u8, words_txt, '\n');
    _ = words_txt_line_iter.next();
    while (words_txt_line_iter.next()) |line| {
        defer characters.clearRetainingCapacity();

        if (line.len == 0) {
            continue;
        }

        const colon_index = std.mem.indexOfScalar(u8, line, ',').?;

        const nahnya = line[0..colon_index];

        var index: usize = 0;

        while (index < nahnya.len) {
            for (character_array) |character| {
                const character_str = @tagName(character);
                if (character_str.len > nahnya.len - index) {
                    continue;
                }

                if (std.mem.eql(u8, nahnya[index .. index + character_str.len], character_str)) {
                    index += character_str.len;
                    try characters.append(gpa, character);
                    break;
                }
            } else {
                for (characters.items) |character| {
                    log.err("added {s}\n", .{@tagName(character)});
                }
                log.err("word: {s}, left: {s}\n", .{ nahnya, nahnya[index..] });
                @panic("shit.");
            }
        }

        // skip single letter words
        if (characters.items.len <= 1) {
            continue;
        }

        try words.append(gpa, .{
            .characters = try characters.toOwnedSlice(gpa),
            .nahnya = nahnya,
        });
    }

    log.debug("Got {d} words", .{words.items.len});

    var out_buf: [1024]u8 = undefined;
    var out_impl = std.fs.File.stdout().writer(&out_buf);
    const out = &out_impl.interface;

    var in_buf: [1024]u8 = undefined;
    var in_impl = std.fs.File.stdin().reader(&in_buf);
    const in = &in_impl.interface;

    var random: std.Random.DefaultPrng = .init(@truncate(@as(u128, @bitCast(std.time.nanoTimestamp()))));

    const word = words.items[@intCast(random.next() % words.items.len)];

    const word_chars_used = try gpa.alloc(bool, word.characters.len);
    defer gpa.free(word_chars_used);

    log.debug("doing word {s}", .{word.nahnya});

    try out.writeAll("Colours:\n");
    try writeColor(out, chunk_even_color);
    try out.writeAll("\tCorrect floa");
    try writeColor(out, chunk_odd_color);
    try out.writeAll("ting chunk\n");
    try writeColor(out, correct_color);
    try out.writeAll("\tCorrect\n");
    try writeColor(out, consonant_color);
    try out.writeAll("\tConsonant is correct, but not vowel\n");
    try writeColor(out, vowel_color);
    try out.writeAll("\tVowel is correct, but not consonant\n");
    try writeColor(out, none_color);
    try out.writeAll("\tCharacter is incorrect\n");
    try writeColor(out, correct_color);
    try out.writeAll("\t(MYH] - The word *starts* with MYH\n");
    try out.writeAll("\t[YHP) - The word *ends* with YHP\n");
    try clearFormatting(out);

    var guess_characters: std.ArrayListUnmanaged(Character) = .empty;
    defer guess_characters.clearAndFree(gpa);

    main_loop: while (true) {
        defer guess_characters.clearAndFree(gpa);

        try out.print("Enter your guess: ", .{});
        try out.flush();

        @memset(word_chars_used, false);

        if (try readInput(in)) |input| {
            _ = std.ascii.upperString(input, input);

            // parse out characters
            var index: usize = 0;
            while (index < input.len) {
                for (character_array) |character| {
                    const character_str = @tagName(character);
                    if (character_str.len > input.len - index) {
                        continue;
                    }

                    if (std.mem.eql(u8, input[index .. index + character_str.len], character_str)) {
                        index += character_str.len;
                        try guess_characters.append(gpa, character);
                        break;
                    }
                } else {
                    for (guess_characters.items) |character| {
                        log.err("added {s}\n", .{@tagName(character)});
                    }
                    log.err("word: {s}, left: {s}\n", .{ input, input[index..] });

                    try out.print("try again... couldn't parse.\n", .{});
                    try out.flush();

                    continue :main_loop;
                }
            }

            const input_characters = guess_characters.items;

            for (words.items) |check_word| {
                if (std.mem.eql(Character, check_word.characters, input_characters)) {
                    break;
                }
            } else {
                try writeColor(out, none_color);
                try out.writeAll("Word not in set.\n");
                try clearFormatting(out);
                try out.flush();

                continue;
            }

            const match_scratch = try gpa.alloc(Character.Comparison, input_characters.len);
            defer gpa.free(match_scratch);

            const Assignment = union(enum) {
                /// Is at the start of the word
                word_start: void,
                /// Is at the end of the word
                word_end: void,
                /// Is a consonant match
                consonant_match: void,
                /// Is a vowel match
                vowel_match: void,
                /// Is a sole matching character
                sole: void,
                /// Is part of a chunk with the specified index
                chunk: usize,
                /// Has no assignment
                none: void,

                pub fn correct(self: @This()) bool {
                    return switch (self) {
                        .word_start => true,
                        .word_end => true,
                        .sole => true,
                        .chunk => true,
                        .consonant_match => false,
                        .vowel_match => false,
                        .none => false,
                    };
                }
            };

            const assignments = try gpa.alloc(Assignment, input_characters.len);
            defer gpa.free(assignments);
            @memset(assignments, .none);

            // start matches
            const num_start_matches = get_start_matches: {
                const start_matches = checkStart(match_scratch, word.characters, input_characters);
                log.debug("start matches: {any}", .{start_matches});

                var num_start_matches: usize = 0;

                // Add the "word start" assignments
                for (start_matches, assignments[0..start_matches.len], word_chars_used[0..start_matches.len]) |start_match, *assignment, *char_used| {
                    if (start_match != .equal) {
                        break;
                    }

                    assignment.* = .word_start;
                    char_used.* = true;
                    num_start_matches += 1;
                }

                break :get_start_matches num_start_matches;
            };

            // end matches
            const num_end_matches = get_end_matches: {
                const end_matches = try checkEnd(gpa, match_scratch, word.characters, input_characters);
                log.debug("end matches: {any}", .{end_matches});

                var num_end_matches: usize = 0;

                // Add the "word end" assignments
                var end_matches_iter = std.mem.reverseIterator(end_matches);
                var assignments_iter = std.mem.reverseIterator(assignments);
                var word_chars_used_iter = std.mem.reverseIterator(word_chars_used);
                while (end_matches_iter.next()) |end_match| {
                    if (end_match != .equal) {
                        break;
                    }

                    assignments_iter.nextPtr().?.* = .word_end;
                    word_chars_used_iter.nextPtr().?.* = true;
                    num_end_matches += 1;
                }

                break :get_end_matches num_end_matches;
            };

            // middle matches, only run when we're not totally 100% complete with the word
            if (num_start_matches != word.characters.len) {
                log.debug("assignments1: {any}", .{assignments});
                log.debug("used1: {any}", .{word_chars_used});

                const search_substring = input_characters[num_start_matches..(input_characters.len - num_end_matches)];
                log.debug("search substring: {any}, {d}, {d}", .{ search_substring, num_start_matches, (input_characters.len - num_end_matches) });
                const assignments_substring = assignments[num_start_matches..(input_characters.len - num_end_matches)];

                const word_start_index = num_start_matches;
                const word_end_index = word.characters.len - num_end_matches;
                log.debug("word substring: {d}, {d}", .{ word_start_index, word_end_index });
                const word_substring = word.characters[word_start_index..word_end_index];
                log.debug("word substring: {any}, {d}, {d}", .{ word_substring, word_start_index, word_end_index });
                const word_used_substring = word_chars_used[word_start_index..word_end_index];
                log.debug("used substring: {any}", .{word_used_substring});

                var chunk_index: usize = 0;

                var len: usize = @min(search_substring.len, word_substring.len);
                while (len > 0) : (len -= 1) {
                    const guess_searches = search_substring.len - len + 1;

                    log.debug("guess searches: {d}", .{guess_searches});

                    for (0..guess_searches) |search_index| {
                        const search = search_substring[search_index .. search_index + len];
                        const search_assignments = assignments_substring[search_index .. search_index + len];

                        const search_matches = match_scratch[0..search.len];

                        const word_searches = word_substring.len - len + 1;
                        for (0..word_searches) |word_search_index| {
                            const word_search = word_substring[word_search_index .. word_search_index + len];
                            const word_used_search = word_used_substring[word_search_index .. word_search_index + len];

                            var not_valid_full_match = false;
                            for (
                                search,
                                word_search,
                                search_matches,
                                search_assignments,
                                word_used_search,
                            ) |
                                search_char,
                                word_char,
                                *match,
                                assignment,
                                *char_used,
                            | {
                                match.* = search_char.compareWith(word_char);

                                if (match.* != .equal or assignment != .none or char_used.*) {
                                    not_valid_full_match = true;
                                }
                            }

                            // it's a full match!
                            if (!not_valid_full_match) {
                                @memset(search_assignments, .{ .chunk = chunk_index });
                                @memset(word_used_search, true);

                                chunk_index += 1;
                            }
                        }
                    }
                }

                for (search_substring, assignments_substring) |search_char, *assignment| {
                    if (assignment.* != .none) {
                        continue;
                    }

                    for (word_substring, word_used_substring) |word_char, *word_used| {
                        log.debug("A: {s}:{s}", .{ @tagName(search_char), @tagName(word_char) });
                        if (word_used.*) {
                            continue;
                        }

                        const comparison = search_char.compareWith(word_char);
                        log.debug("comparison: {any}", .{comparison});

                        switch (comparison) {
                            .different => continue,
                            .equal => {
                                word_used.* = true;
                                assignment.* = .sole;
                            },
                            .same_consonant => {
                                assignment.* = .consonant_match;
                                word_used.* = true;
                            },
                            .same_vowel => {
                                assignment.* = .vowel_match;
                                word_used.* = true;
                            },
                        }
                    }
                }
            }
            log.debug("assignments2: {any}", .{assignments});

            var all_correct = assignments.len == word.characters.len;
            for (assignments) |assignment| {
                if (!assignment.correct()) {
                    all_correct = false;
                }
            }

            var mebi_last_assignment: ?Assignment = null;
            for (assignments, input_characters) |assignment, input_character| {
                defer mebi_last_assignment = assignment;

                const input_str = @tagName(input_character);

                if (mebi_last_assignment) |last_assignment| {
                    if (last_assignment == .word_start and assignment != .word_start) {
                        try out.writeByte(']');
                    }

                    if (last_assignment != .word_end and assignment == .word_end) {
                        try out.writeByte('[');
                    }
                } else {
                    if (assignment == .word_start) {
                        try out.writeByte('(');
                    }
                }

                switch (assignment) {
                    .chunk => |chunk_id| {
                        const even = (chunk_id % 2) == 0;

                        if (even) {
                            try writeColor(out, chunk_even_color);
                        } else {
                            try writeColor(out, chunk_odd_color);
                        }
                    },
                    .word_start, .word_end, .sole => {
                        try writeColor(out, correct_color);
                    },
                    .consonant_match => {
                        try writeColor(out, consonant_color);
                    },
                    .vowel_match => {
                        try writeColor(out, vowel_color);
                    },
                    .none => {
                        try writeColor(out, none_color);
                    },
                }

                try out.writeAll(input_str);

                try clearFormatting(out);
            }

            if (mebi_last_assignment) |last_assignment| {
                if (last_assignment == .word_end) {
                    try out.writeByte(')');
                }
            }

            try out.writeByte('\n');
            try out.flush();

            if (all_correct) {
                try writeColor(out, correct_color);
                try out.print("YOU'RE WINNER. WORD WAS {s}\n", .{word.nahnya});
                try clearFormatting(out);
                try out.flush();

                break;
            }
        } else {
            try out.print("Exiting...\n", .{});
            try out.flush();

            break;
        }
    }
}
