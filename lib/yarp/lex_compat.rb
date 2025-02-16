# frozen_string_literal: true

require "delegate"

module YARP
  # This class is responsible for lexing the source using YARP and then
  # converting those tokens to be compatible with Ripper. In the vast majority
  # of cases, this is a one-to-one mapping of the token type. Everything else
  # generally lines up. However, there are a few cases that require special
  # handling.
  class LexCompat
    # This is a mapping of YARP token types to Ripper token types. This is a
    # many-to-one mapping because we split up our token types, whereas Ripper
    # tends to group them.
    RIPPER = {
      AMPERSAND: :on_op,
      AMPERSAND_AMPERSAND: :on_op,
      AMPERSAND_AMPERSAND_EQUAL: :on_op,
      AMPERSAND_DOT: :on_op,
      AMPERSAND_EQUAL: :on_op,
      BACK_REFERENCE: :on_backref,
      BACKTICK: :on_backtick,
      BANG: :on_op,
      BANG_EQUAL: :on_op,
      BANG_TILDE: :on_op,
      BRACE_LEFT: :on_lbrace,
      BRACE_RIGHT: :on_rbrace,
      BRACKET_LEFT: :on_lbracket,
      BRACKET_LEFT_ARRAY: :on_lbracket,
      BRACKET_LEFT_RIGHT: :on_op,
      BRACKET_LEFT_RIGHT_EQUAL: :on_op,
      BRACKET_RIGHT: :on_rbracket,
      CARET: :on_op,
      CARET_EQUAL: :on_op,
      CHARACTER_LITERAL: :on_CHAR,
      CLASS_VARIABLE: :on_cvar,
      COLON: :on_op,
      COLON_COLON: :on_op,
      COMMA: :on_comma,
      COMMENT: :on_comment,
      CONSTANT: :on_const,
      DOT: :on_period,
      DOT_DOT: :on_op,
      DOT_DOT_DOT: :on_op,
      EMBDOC_BEGIN: :on_embdoc_beg,
      EMBDOC_END: :on_embdoc_end,
      EMBDOC_LINE: :on_embdoc,
      EMBEXPR_BEGIN: :on_embexpr_beg,
      EMBEXPR_END: :on_embexpr_end,
      EMBVAR: :on_embvar,
      EOF: :on_eof,
      EQUAL: :on_op,
      EQUAL_EQUAL: :on_op,
      EQUAL_EQUAL_EQUAL: :on_op,
      EQUAL_GREATER: :on_op,
      EQUAL_TILDE: :on_op,
      FLOAT: :on_float,
      GREATER: :on_op,
      GREATER_EQUAL: :on_op,
      GREATER_GREATER: :on_op,
      GREATER_GREATER_EQUAL: :on_op,
      GLOBAL_VARIABLE: :on_gvar,
      HEREDOC_END: :on_heredoc_end,
      HEREDOC_START: :on_heredoc_beg,
      IDENTIFIER: :on_ident,
      IGNORED_NEWLINE: :on_ignored_nl,
      IMAGINARY_NUMBER: :on_imaginary,
      INTEGER: :on_int,
      INSTANCE_VARIABLE: :on_ivar,
      INVALID: :INVALID,
      KEYWORD___ENCODING__: :on_kw,
      KEYWORD___LINE__: :on_kw,
      KEYWORD___FILE__: :on_kw,
      KEYWORD_ALIAS: :on_kw,
      KEYWORD_AND: :on_kw,
      KEYWORD_BEGIN: :on_kw,
      KEYWORD_BEGIN_UPCASE: :on_kw,
      KEYWORD_BREAK: :on_kw,
      KEYWORD_CASE: :on_kw,
      KEYWORD_CLASS: :on_kw,
      KEYWORD_DEF: :on_kw,
      KEYWORD_DEFINED: :on_kw,
      KEYWORD_DO: :on_kw,
      KEYWORD_DO_LOOP: :on_kw,
      KEYWORD_ELSE: :on_kw,
      KEYWORD_ELSIF: :on_kw,
      KEYWORD_END: :on_kw,
      KEYWORD_END_UPCASE: :on_kw,
      KEYWORD_ENSURE: :on_kw,
      KEYWORD_FALSE: :on_kw,
      KEYWORD_FOR: :on_kw,
      KEYWORD_IF: :on_kw,
      KEYWORD_IN: :on_kw,
      KEYWORD_MODULE: :on_kw,
      KEYWORD_NEXT: :on_kw,
      KEYWORD_NIL: :on_kw,
      KEYWORD_NOT: :on_kw,
      KEYWORD_OR: :on_kw,
      KEYWORD_REDO: :on_kw,
      KEYWORD_RESCUE: :on_kw,
      KEYWORD_RETRY: :on_kw,
      KEYWORD_RETURN: :on_kw,
      KEYWORD_SELF: :on_kw,
      KEYWORD_SUPER: :on_kw,
      KEYWORD_THEN: :on_kw,
      KEYWORD_TRUE: :on_kw,
      KEYWORD_UNDEF: :on_kw,
      KEYWORD_UNLESS: :on_kw,
      KEYWORD_UNTIL: :on_kw,
      KEYWORD_WHEN: :on_kw,
      KEYWORD_WHILE: :on_kw,
      KEYWORD_YIELD: :on_kw,
      LABEL: :on_label,
      LAMBDA_BEGIN: :on_tlambeg,
      LESS: :on_op,
      LESS_EQUAL: :on_op,
      LESS_EQUAL_GREATER: :on_op,
      LESS_LESS: :on_op,
      LESS_LESS_EQUAL: :on_op,
      MINUS: :on_op,
      MINUS_EQUAL: :on_op,
      MINUS_GREATER: :on_tlambda,
      NEWLINE: :on_nl,
      NTH_REFERENCE: :on_backref,
      PARENTHESIS_LEFT: :on_lparen,
      PARENTHESIS_RIGHT: :on_rparen,
      PERCENT: :on_op,
      PERCENT_EQUAL: :on_op,
      PERCENT_LOWER_I: :on_qsymbols_beg,
      PERCENT_LOWER_W: :on_qwords_beg,
      PERCENT_LOWER_X: :on_backtick,
      PERCENT_UPPER_I: :on_symbols_beg,
      PERCENT_UPPER_W: :on_words_beg,
      PIPE: :on_op,
      PIPE_EQUAL: :on_op,
      PIPE_PIPE: :on_op,
      PIPE_PIPE_EQUAL: :on_op,
      PLUS: :on_op,
      PLUS_EQUAL: :on_op,
      QUESTION_MARK: :on_op,
      RATIONAL_NUMBER: :on_rational,
      REGEXP_BEGIN: :on_regexp_beg,
      REGEXP_END: :on_regexp_end,
      SEMICOLON: :on_semicolon,
      SLASH: :on_op,
      SLASH_EQUAL: :on_op,
      STAR: :on_op,
      STAR_EQUAL: :on_op,
      STAR_STAR: :on_op,
      STAR_STAR_EQUAL: :on_op,
      STRING_BEGIN: :on_tstring_beg,
      STRING_CONTENT: :on_tstring_content,
      STRING_END: :on_tstring_end,
      SYMBOL_BEGIN: :on_symbeg,
      TILDE: :on_op,
      UMINUS: :on_op,
      UPLUS: :on_op,
      WORDS_SEP: :on_words_sep,
      __END__: :on___end__
    }.freeze

    # When we produce tokens, we produce the same arrays that Ripper does.
    # However, we add a couple of convenience methods onto them to make them a
    # little easier to work with. We delegate all other methods to the array.
    class Token < SimpleDelegator
      def location
        self[0]
      end
  
      def event
        self[1]
      end
  
      def value
        self[2]
      end
  
      def state
        self[3]
      end
  
      def state=(val)
        self[3] = val
      end
    end
  
    # Ripper doesn't include the rest of the token in the event, so we need to
    # trim it down to just the content on the first line when comparing.
    class EndContentToken < Token
      def ==(other)
        [self[0], self[1], self[2][0..self[2].index("\n")], self[3]] == other
      end
    end
  
    # It is extremely non obvious which state the parser is in when comments get
    # dispatched. Because of this we don't both comparing state when comparing
    # against other comment tokens.
    class CommentToken < Token
      def ==(other)
        self[0...-1] == other[0...-1]
      end
    end

    class IdentToken < Token
      def ==(other)
        self[0...-1] == other[0...-1]
      end
    end

    # A heredoc in this case is a list of tokens that belong to the body of the
    # heredoc that should be appended onto the list of tokens when the heredoc
    # closes.
    module Heredoc
      # Heredocs that are no dedent heredocs are just a list of tokens. We need
      # to keep them around so that we can insert them in the correct order back
      # into the token stream and set the state of the last token to the state
      # that the heredoc was opened in.
      class RegularHeredoc
        attr_reader :state, :tokens

        def initialize(state)
          @state = state
          @tokens = []
        end

        def <<(token)
          tokens << token
        end

        def to_a
          tokens.last.state = state
          tokens
        end
      end

      # Heredocs that are dedenting heredocs are a little more complicated.
      # Ripper outputs on_ignored_sp tokens for the whitespace that is being
      # removed from the output. YARP only modifies the node itself and keeps
      # the token the same. This simplifies YARP, but makes comparing against
      # Ripper much harder because there is a length mismatch.
      #
      # Fortunately, we already have to pull out the heredoc tokens in order to
      # insert them into the stream in the correct order. As such, we can do
      # some extra manipulation on the tokens to make them match Ripper's
      # output by mirroring the dedent logic that Ripper uses.
      class DedentingHeredoc
        TAB_WIDTH = 8

        attr_reader :state, :tokens, :dedent_next, :dedent

        def initialize(state)
          @state = state
          @tokens = []

          @dedent_next = true
          @dedent = nil
        end

        # As tokens are coming in, we track the minimum amount of common leading
        # whitespace on plain string content tokens. This allows us to later
        # remove that amount of whitespace from the beginning of each line.
        def <<(token)
          if dedent_next && token.event == :on_tstring_content && token.value.start_with?(/\s/)
            token.value.split("\n").each do |line|
              leading = line[/\A\s*/]
              @dedent = [dedent, leading.length + (leading.count("\t") * (TAB_WIDTH - 1))].compact.min
            end
          end

          @dedent_next = token.event == :on_tstring_content
          tokens << token
        end

        def to_a
          # First set the final state correctly. Next, check if there is
          # anything to dedent. If there isn't, then we can return the tokens
          # directly since no on_ignored_sp tokens need to be inserted.
          tokens.last.state = state
          return tokens if dedent.nil? || dedent == 0

          # Otherwise, we're going to run through each token in the list and
          # insert on_ignored_sp tokens for the amount of dedent that we need to
          # perform. We also need to remove the dedent from the beginning of
          # each line of plain string content tokens.
          results = []
          dedent_next = true

          tokens.each do |token|
            # Notice that the structure of this conditional largely matches the
            # whitespace calculation we performed above. This is because
            # checking if the subsequent token needs to be dedented is common to
            # both the dedent calculation and the ignored_sp insertion.
            if token.event == :on_tstring_content
              # Here we're going to split the string on newlines, but maintain
              # the newlines in the resulting array. We'll do that with a look
              # behind assertion.
              token.value.split(/(?<=\n)/).each_with_index do |line, index|
                lineno = token[0][0] + index
                column = token[0][1]

                # If we are supposed to dedent this line or if this is not the
                # first line of the string, then we need to insert an
                # on_ignored_sp token and remove the dedent from the beginning
                # of the line.
                if dedent_next || index > 0
                  deleting = 0
                  deleted_chars = []

                  # Gather up all of the characters that we're going to delete,
                  # stopping when you hit a character that would put you over
                  # the dedent amount.
                  line.each_char do |char|
                    break if (deleting += char == "\t" ? TAB_WIDTH : 1) > dedent
                    deleted_chars << char
                  end

                  # If we have something to delete, then delete it from the
                  # string and insert an on_ignored_sp token.
                  if deleted_chars.any?
                    ignored = deleted_chars.join
                    line.delete_prefix!(ignored)

                    results << Token.new([[lineno, 0], :on_ignored_sp, ignored, token[3]])
                    column += ignored.length
                  end
                end

                results << Token.new([[lineno, column], token[1], line, token[3]]) unless line.empty?
              end

              dedent_next = true
            else
              dedent_next = false
              results << token
            end
          end

          results
        end
      end

      # Here we will split between the two types of heredocs and return the
      # object that will store their tokens.
      def self.build(opening, state)
        if opening.value[2] == "~"
          DedentingHeredoc.new(state)
        else
          RegularHeredoc.new(state)
        end
      end
    end

    attr_reader :source, :offsets

    def initialize(source)
      @source = source
      @offsets = find_offsets(source)
    end

    def result
      tokens = []

      state = :default
      heredocs = []

      result = YARP.lex(source)
      result_value = result.value
      previous_state = nil

      # If there's a UTF-8 byte-order mark as the start of the file, then ripper
      # sets every token's on the first line back by 6 bytes. It also keeps the
      # byte order mark in the first token's value. This is weird, and I don't
      # want to mirror that in our parser. So instead, we'll match up the values
      # here, and then match up the locations as we process the tokens.
      bom = source.bytes[0..2] == [0xEF, 0xBB, 0xBF]
      result_value[0][0].value.prepend("\xEF\xBB\xBF") if bom

      result_value.each_with_index do |(token, lex_state), index|
        (lineno, column) = find_location(token.location.start_offset)
        column -= 6 if bom && lineno == 1

        event = RIPPER.fetch(token.type)
        value = token.value
        lex_state = Ripper::Lexer::State.new(lex_state)

        token =
          case event
          when :on___end__
            EndContentToken.new([[lineno, column], event, value, lex_state])
          when :on_comment
            CommentToken.new([[lineno, column], event, value, lex_state])
          when :on_ident
            if lex_state == Ripper::EXPR_END | Ripper::EXPR_LABEL
              # In the event that we're comparing identifiers, we're going to
              # allow a little divergence. Ripper doesn't account for local
              # variables introduced through named captures in regexes, and we
              # do, which accounts for this difference.
              IdentToken.new([[lineno, column], event, value, lex_state])
            else
              Token.new([[lineno, column], event, value, lex_state])
            end
          when :on_regexp_end
            # On regex end, Ripper scans and then sets end state, so the ripper
            # lexed output is begin, when it should be end. YARP sets lex state
            # correctly to end state, but we want to be able to compare against
            # Ripper's lexed state. So here, if it's a regexp end token, we
            # output the state as the previous state, solely for the sake of
            # comparison.
            previous_token = result_value[index - 1][0]
            lex_state = 
              if RIPPER.fetch(previous_token.type) == :on_embexpr_end
                # If the previous token is embexpr_end, then we have to do even
                # more processing. The end of an embedded expression sets the
                # state to the state that it had at the beginning of the
                # embedded expression. So we have to go and find that state and
                # set it here.
                counter = 1
                current_index = index - 1

                until counter == 0
                  current_index -= 1
                  current_event = RIPPER.fetch(result_value[current_index][0].type)
                  counter += { on_embexpr_beg: -1, on_embexpr_end: 1 }[current_event] || 0
                end

                Ripper::Lexer::State.new(result_value[current_index][1])
              else
                previous_state
              end

            Token.new([[lineno, column], event, value, lex_state])
          else
            Token.new([[lineno, column], event, value, lex_state])
          end

        previous_state = lex_state

        # The order in which tokens appear in our lexer is different from the
        # order that they appear in Ripper. When we hit the declaration of a
        # heredoc in YARP, we skip forward and lex the rest of the content of
        # the heredoc before going back and lexing at the end of the heredoc
        # identifier.
        #
        # To match up to ripper, we keep a small state variable around here to
        # track whether we're in the middle of a heredoc or not. In this way we
        # can shuffle around the token to match Ripper's output.
        case state
        when :default
          tokens << token

          if event == :on_heredoc_beg
            state = :heredoc_opened
            heredocs << Heredoc.build(token, lex_state)
          end
        when :heredoc_opened
          heredocs.last << token
          state = :heredoc_closed if event == :on_heredoc_end
        when :heredoc_closed
          tokens << token

          case event
          when :on_nl, :on_ignored_nl
            heredocs.each do |heredoc|
              tokens.concat(heredoc.to_a)
            end

            heredocs.clear
            state = :default
          when :on_heredoc_beg
            state = :heredoc_opened
            heredocs << Heredoc.build(token, lex_state)
          end
        end
      end

      ParseResult.new(tokens[0...-1], result.comments, result.errors, result.warnings)
    end

    private

    # YARP keeps locations around in the form of ranges of byte offsets from the
    # start of the file. Ripper keeps locations around in the form of line and
    # column numbers. To match the output, we keep a cache of the offsets at the
    # beginning of each line.
    def find_offsets(source)
      last_offset = 0
      offsets = [0]

      source.each_line do |line|
        last_offset += line.bytesize
        offsets << last_offset
      end

      offsets
    end

    # Given a byte offset, find the line number and column number that it maps
    # to. We use a binary search over the cached offsets to find the line number
    # that the offset is on, and then subtract the offset of the previous line
    # to find the column number.
    def find_location(value)
      line_number = offsets.bsearch_index { |offset| offset > value }
      line_offset = offsets[line_number - 1] if line_number

      [
        line_number || offsets.length - 1,
        value - (line_offset || offsets.last)
      ]
    end
  end

  # The constant that wraps the behavior of the lexer to match Ripper's output
  # is an implementation detail, so we don't want it to be public.
  private_constant :LexCompat

  # Returns an array of tokens that closely resembles that of the Ripper lexer.
  # The only difference is that since we don't keep track of lexer state in the
  # same way, it's going to always return the NONE state.
  def self.lex_compat(source)
    LexCompat.new(source).result
  end
end
