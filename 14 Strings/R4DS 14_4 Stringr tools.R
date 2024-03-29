library(tidyverse)

# Here we'll learn the stringr functions that help you actually work with regex and matches

#### Detect Matches ####
# str_detect() detects matches
x <- c("apple", "banana", "pear")
str_detect(x, "e")

# It can be useful to just use str_detect and logical operators instead of more complext regexs
no_vowels_1 <- !str_detect(words, "[aeiou]")
no_vowels_2 <- str_detect(words, "^[^aeiou]+$")
identical(no_vowels_1, no_vowels_2)

# To extract the words that match your string, you can use logical subsetting
words[str_detect(words, "x$")]
# Or the subset function
str_subset(words, "x$")

# Whent the strings are part of a df though, you'll want to use a filter
df <- tibble(
  word = words, 
  i = seq_along(word) # just creates a sequence of numbers
)

df %>% 
  filter(str_detect(word, "x$"))

# str_count() tells you how many matches there are in a string
x <- c("apple", "banana", "pear")
str_count(x, "a")

# On average, how many vowels per word?
mean(str_count(words, "[aeiou]"))

# You can often use str_count() with mutate
df %>% 
  mutate(
    vowels = str_count(word, "[aeiou]"),
    consonants = str_count(word, "[^aeiou]")
  )

# Regular expressions never overlap, they're always distinct
str_view_all("abababa", "aba")
# Lots of stringr functions come in pairs. One for a single match, and a corresponding _all version


#### Questions ####
# 1. For each of the following challenges, try solving it by using both a single 
#   regular expression, and a combination of multiple str_detect() calls.
# Find all words that start or end with x
x <- str_detect(words, "^x|x$")
y <- str_detect(words, "^x") | str_detect(words, "x$")
identical(x, y)

# Find all words that start with a vowel and end with a consonant
x <- str_detect(words, "^[aeiou].*[^aeiou]$")
y <- str_detect(words, "^[aeiou]") & str_detect(words, "[^aeiou]$")
identical(x, y)

# Are there any words that contain at least one of each different vowel?
# Doing this as a regex is very complicated (this is their working)
pattern <-
  cross(rerun(5, c("a", "e", "i", "o", "u")),
        .filter = function(...) {
          x <- as.character(unlist(list(...)))
          length(x) != length(unique(x))
        }
  ) %>%
  map_chr(~str_c(unlist(.x), collapse = ".*")) %>%
  str_c(collapse = "|")

# It's much more readable to just do it as a group of detects
sum(str_detect(words, "[a]") & str_detect(words, "[e]") & 
      str_detect(words, "[i]") & str_detect(words, "[o]") & str_detect(words, "[u]"))

# 2. What word has the highest number of vowels? 
#  What word has the highest proportion of vowels? (Hint: what is the denominator?)
# There are 8 words with 5 vowels each
# "a" has the highest proportion of vowels, after that it's "area" and "idea"
df %>%
  mutate(
    vowels = str_count(word, "[aeiou]"),
    consonants = str_count(word, "[^aeiou]"),
    total = vowels + consonants,
    prop = vowels / total
  ) %>%
  arrange(desc(prop))

# For count of vowels there's a much simpler way:
vowels <- str_count(words, "[aeiou]")
words[which(vowels == max(vowels))]


#### Extract Matches ####
# To do extraction we're going to use the Harvard sentences set
head(sentences)

# Lets find all the sentences that contain a colour
colours <- c("red", "orange", "yellow", "green", "blue", "purple")
colour_match <- str_c(colours, collapse = "|")

# Select only the sentences with a colour
has_colour <- str_subset(sentences, colour_match)
# Then extract the colour to see what it is
matches <- str_extract(has_colour, colour_match)
head(matches)

# str_extract() only lets you see the first match
more <- sentences[str_count(sentences, colour_match) > 1]
str_view_all(more, colour_match)

# You have to add the _all to make it see more than the first
str_extract(more, colour_match)
str_extract_all(more, colour_match)

# simplify turns the result of the _all from a set of lists to a matrix
str_extract_all(more, colour_match, simplify = TRUE)

# Short matches are expanded to the same length as the longest
x <- c("a", "a b", "a b c")
str_extract_all(x, "[a-z]", simplify = TRUE)


#### Questions ####
# 1. In the previous example, you might have noticed that the regular expression 
#   matched "flickered", which is not a colour. Modify the regex to fix the problem.
# Adding a word break fixes that problem
colours <- c("\\bred", "orange", "yellow", "green", "blue", "purple")
colour_match <- str_c(colours, collapse = "|")
more <- sentences[str_count(sentences, colour_match) > 1]
str_view_all(more, colour_match)

# 2. From the Harvard sentences data, extract:
# The first word from each sentence
str_extract(sentences, "[A-Za-z][A-Za-z']*") %>% head()

# All words ending in "ing"
pattern <- "\\b[A-Za-z]+ing\\b"
sentences_with_ing <- str_detect(sentences, pattern)
unique(unlist(str_extract_all(sentences[sentences_with_ing], pattern))) %>%
  head()

# All plurals
unique(unlist(str_extract_all(sentences, "\\b[A-Za-z]{3,}s\\b"))) %>%
  head()


#### Grouped Matches ####
# You can also use groups to extract the different subsections of a regex match
# Lets say we're looking for nouns, approximated by coming after a or the
noun <- "(a|the) ([^ ]+)"

has_noun <- sentences %>%
  str_subset(noun) %>%
  head(10)

has_noun %>% 
  str_extract(noun)

# str_extract() takes out the whole thing. str_match() also gives us each component
has_noun %>%
  str_match(noun)

# If the original data is a tibble, you can also use extract(), which makes the matches into columns
tibble(sentence = sentences) %>% 
  extract(
    sentence, c("article", "noun"), "(a|the) ([^ ]+)", 
    remove = FALSE
  )


#### Questions ####
# 1. Find all words that come after a "number" like "one", "two", "three" etc. 
#   Pull out both the number and the word.
# I'm only going to do words up to 10,
numbers <- c("one", "two", "three", "four", "five", "six", "seven", "eight", "nine", "ten", "[0-9]+")
num_match <- str_c(numbers, collapse = "|")
num_match <- str_c("(", num_match, ")", " ([^ ]+)", sep = "")

tibble(sentence = sentences) %>% 
  extract(
    sentence, c("number", "word"), num_match, 
    remove = FALSE
  ) %>%
  drop_na()
  na.exclude() # Not sure what the difference between these is

# They did it like this:
numword <- "\\b(one|two|three|four|five|six|seven|eight|nine|ten) +(\\w+)"
sentences[str_detect(sentences, numword)] %>%
  str_extract(numword)

# 2. Find all contractions. Seperate out the pieces before and after the apostrophe
tibble(sentence = sentences) %>% 
  extract(
    sentence, c("before", "after"), "([^ ]+)'([^ ]+)", 
    remove = FALSE
  ) %>%
  na.exclude()

# And they did it like this:
contraction <- "([A-Za-z]+)'([A-Za-z]+)"
sentences[str_detect(sentences, contraction)] %>%
  str_extract(contraction) %>%
  str_split("'")


#### Replacing Matches ####
# str_replace() and str_replace_all() let you replace matches with new strings
x <- c("apple", "pear", "banana")
str_replace(x, "[aeiou]", "-")
str_replace_all(x, "[aeiou]", "-")

# For replace all you can supply a named vector which means you can replace multople things
x <- c("1 house", "2 cars", "3 people")
str_replace_all(x, c("1" = "one", "2" = "two", "3" = "three"))

# You can also work with components of your string using backreferences
# This code swaps the second and third words
sentences %>% 
  str_replace("([^ ]+) ([^ ]+) ([^ ]+)", "\\1 \\3 \\2") %>% 
  head(5)


#### Questions ####
# 1. Replace all forward slashes with backslashes
slash_string <- "This /string has m/an/y fo/rward / slash//es"

slash_string %>%
  str_replace_all("/", "\\\\") # For some reason it's printing two backslashes

# 2. Implement a simple version of str_to_lower() using replace_all()
# cba to add a whole dict of upper and lower case characters
replacements <- c("A" = "a", "B" = "b", "C" = "c", "D" = "d", "E" = "e",
                  "F" = "f", "G" = "g", "H" = "h", "I" = "i", "J" = "j", 
                  "K" = "k", "L" = "l", "M" = "m", "N" = "n", "O" = "o", 
                  "P" = "p", "Q" = "q", "R" = "r", "S" = "s", "T" = "t", 
                  "U" = "u", "V" = "v", "W" = "w", "X" = "x", "Y" = "y", 
                  "Z" = "z")
lower_words <- str_replace_all(words, pattern = replacements)
head(lower_words)

# 3. Switch the first and last letters in words. Which of those strings are still words?
new_words <- words %>%
  str_replace("(^.)(.*)(.$)", "\\3\\2\\1")
# To find if they're still words you'd want to check them against the words set
intersect(new_words, words)


#### Splitting ####
# str_split() splits a string off into pieces
sentences %>%
  head(5) %>% 
  str_split(" ")

# This returns a list because each element might be a different length
# You can also turn them into a matrix
sentences %>%
  head(5) %>% 
  str_split(" ", simplify = TRUE)

# You can also set a max number of pieces (here I don't think it makes a difference)
fields <- c("Name: Hadley", "Country: NZ", "Age: 35")
fields %>% str_split(": ", n = 2, simplify = TRUE)

# You can also split by character, line and word boundaries
x <- "This is a sentence.  This is another sentence."
str_view_all(x, boundary("word"))

str_split(x, " ")[[1]]
str_split(x, boundary("word"))[[1]]


#### Questions ####
# 1. Split up a string like "apples, pears, and bananas" into individual components.
x <- "apples, pears, and bananas"
str_split(x, ", +(and +)?")[[1]]

# 2. Why is it better to split up by boundary("word") than " "?
# Splitting by word boundary takes things like punctuation into account

# 3. What does splitting with an empty string ("") do? Experiment, and then read the documentation.
# Splits each character apart
# The same as boundary(character)
str_split(x, "")[[1]]


#### Find Matches ####
# str_locate() and str_locate_all() give you the start and end position of each match
#   These are useful when none of the other functions do exactly what you want
#   You can locate the string and then use str_sub() to extract or modify it
