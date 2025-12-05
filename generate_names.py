#!/usr/bin/env python3
import json

# Read existing names
with open('/Users/jdecker/projects/ios/name/NameMatch/Resources/names.json', 'r') as f:
    existing_names = json.load(f)

# Create a comprehensive list of additional names
# This includes popular, uncommon, and diverse names from many cultures

additional_names = [
    # Popular Male Names
    {"id": "aiden", "name": "Aiden", "gender": "male", "origins": ["irish"], "styles": ["modern", "strong"], "meaning": "Little fire", "popularity": "popular"},
    {"id": "jackson", "name": "Jackson", "gender": "male", "origins": ["english"], "styles": ["modern", "strong"], "meaning": "Son of Jack", "popularity": "popular"},
    {"id": "logan", "name": "Logan", "gender": "male", "origins": ["scottish"], "styles": ["modern", "strong"], "meaning": "Small hollow", "popularity": "popular"},
    {"id": "lucas", "name": "Lucas", "gender": "male", "origins": ["latin"], "styles": ["classic", "modern"], "meaning": "Light", "popularity": "popular"},
    {"id": "michael", "name": "Michael", "gender": "male", "origins": ["hebrew"], "styles": ["classic", "biblical"], "meaning": "Who is like God", "popularity": "popular"},

    # Popular Female Names
    {"id": "emma", "name": "Emma", "gender": "female", "origins": ["german"], "styles": ["classic", "vintage"], "meaning": "Universal", "popularity": "popular"},
    {"id": "olivia", "name": "Olivia", "gender": "female", "origins": ["latin"], "styles": ["classic", "literary"], "meaning": "Olive tree", "popularity": "popular"},
    {"id": "ava", "name": "Ava", "gender": "female", "origins": ["latin"], "styles": ["modern", "elegant"], "meaning": "Life", "popularity": "popular"},
    {"id": "sophia", "name": "Sophia", "gender": "female", "origins": ["greek"], "styles": ["classic", "elegant"], "meaning": "Wisdom", "popularity": "popular"},
    {"id": "isabella", "name": "Isabella", "gender": "female", "origins": ["italian", "spanish"], "styles": ["classic", "royal"], "meaning": "Devoted to God", "popularity": "popular"},
    {"id": "mia", "name": "Mia", "gender": "female", "origins": ["italian", "scandinavian"], "styles": ["modern", "gentle"], "meaning": "Mine", "popularity": "popular"},
    {"id": "charlotte", "name": "Charlotte", "gender": "female", "origins": ["french"], "styles": ["classic", "royal"], "meaning": "Free woman", "popularity": "popular"},
    {"id": "amelia", "name": "Amelia", "gender": "female", "origins": ["german"], "styles": ["classic", "vintage"], "meaning": "Industrious", "popularity": "popular"},
    {"id": "harper", "name": "Harper", "gender": "female", "origins": ["english"], "styles": ["modern", "literary"], "meaning": "Harp player", "popularity": "popular"},
    {"id": "evelyn", "name": "Evelyn", "gender": "female", "origins": ["english"], "styles": ["vintage", "elegant"], "meaning": "Desired", "popularity": "popular"},

    # Nature Names
    {"id": "river", "name": "River", "gender": "neutral", "origins": ["english"], "styles": ["nature", "modern"], "meaning": "Flowing water", "popularity": "common"},
    {"id": "sage", "name": "Sage", "gender": "neutral", "origins": ["latin"], "styles": ["nature", "bohemian"], "meaning": "Wise one", "popularity": "common"},
    {"id": "willow", "name": "Willow", "gender": "female", "origins": ["english"], "styles": ["nature", "gentle"], "meaning": "Willow tree", "popularity": "common"},
    {"id": "aspen", "name": "Aspen", "gender": "neutral", "origins": ["english"], "styles": ["nature", "modern"], "meaning": "Quaking tree", "popularity": "uncommon"},
    {"id": "ivy", "name": "Ivy", "gender": "female", "origins": ["english"], "styles": ["nature", "vintage"], "meaning": "Climbing plant", "popularity": "common"},
    {"id": "hazel", "name": "Hazel", "gender": "female", "origins": ["english"], "styles": ["nature", "vintage"], "meaning": "Hazelnut tree", "popularity": "common"},
    {"id": "jasper", "name": "Jasper", "gender": "male", "origins": ["persian"], "styles": ["nature", "vintage"], "meaning": "Treasurer", "popularity": "uncommon"},
    {"id": "rowan", "name": "Rowan", "gender": "neutral", "origins": ["irish"], "styles": ["nature", "celtic"], "meaning": "Little red one", "popularity": "uncommon"},
    {"id": "oak", "name": "Oak", "gender": "male", "origins": ["english"], "styles": ["nature", "strong"], "meaning": "Oak tree", "popularity": "rare"},
    {"id": "wren", "name": "Wren", "gender": "female", "origins": ["english"], "styles": ["nature", "gentle"], "meaning": "Small bird", "popularity": "uncommon"},

    # International Names
    {"id": "santiago", "name": "Santiago", "gender": "male", "origins": ["spanish"], "styles": ["classic", "strong"], "meaning": "Saint James", "popularity": "common"},
    {"id": "diego", "name": "Diego", "gender": "male", "origins": ["spanish"], "styles": ["classic", "strong"], "meaning": "Supplanter", "popularity": "common"},
    {"id": "sofia", "name": "Sofia", "gender": "female", "origins": ["spanish", "italian"], "styles": ["classic", "elegant"], "meaning": "Wisdom", "popularity": "popular"},
    {"id": "aria", "name": "Aria", "gender": "female", "origins": ["italian"], "styles": ["modern", "artistic"], "meaning": "Air, melody", "popularity": "popular"},
    {"id": "luna", "name": "Luna", "gender": "female", "origins": ["latin", "spanish"], "styles": ["modern", "mystical"], "meaning": "Moon", "popularity": "popular"},
    {"id": "kai", "name": "Kai", "gender": "neutral", "origins": ["hawaiian", "japanese"], "styles": ["modern", "nature"], "meaning": "Sea", "popularity": "common"},
    {"id": "yuki", "name": "Yuki", "gender": "neutral", "origins": ["japanese"], "styles": ["modern", "gentle"], "meaning": "Snow", "popularity": "uncommon"},
    {"id": "arjun", "name": "Arjun", "gender": "male", "origins": ["indian"], "styles": ["classic", "strong"], "meaning": "Bright, shining", "popularity": "common"},
    {"id": "priya", "name": "Priya", "gender": "female", "origins": ["indian"], "styles": ["classic", "gentle"], "meaning": "Beloved", "popularity": "common"},
    {"id": "omar", "name": "Omar", "gender": "male", "origins": ["arabic"], "styles": ["classic", "strong"], "meaning": "Flourishing", "popularity": "common"},
    {"id": "layla", "name": "Layla", "gender": "female", "origins": ["arabic"], "styles": ["classic", "romantic"], "meaning": "Night", "popularity": "popular"},
    {"id": "zara", "name": "Zara", "gender": "female", "origins": ["arabic"], "styles": ["modern", "elegant"], "meaning": "Princess", "popularity": "common"},

    # Vintage/Classic Names
    {"id": "theodore", "name": "Theodore", "gender": "male", "origins": ["greek"], "styles": ["vintage", "classic"], "meaning": "Gift of God", "popularity": "popular"},
    {"id": "arthur", "name": "Arthur", "gender": "male", "origins": ["celtic"], "styles": ["vintage", "royal"], "meaning": "Bear", "popularity": "common"},
    {"id": "felix", "name": "Felix", "gender": "male", "origins": ["latin"], "styles": ["vintage", "cheerful"], "meaning": "Happy, fortunate", "popularity": "uncommon"},
    {"id": "augustus", "name": "Augustus", "gender": "male", "origins": ["latin"], "styles": ["vintage", "royal"], "meaning": "Great, magnificent", "popularity": "uncommon"},
    {"id": "beatrice", "name": "Beatrice", "gender": "female", "origins": ["latin"], "styles": ["vintage", "literary"], "meaning": "She who brings happiness", "popularity": "uncommon"},
    {"id": "clara", "name": "Clara", "gender": "female", "origins": ["latin"], "styles": ["vintage", "classic"], "meaning": "Bright, clear", "popularity": "common"},
    {"id": "eleanor", "name": "Eleanor", "gender": "female", "origins": ["french"], "styles": ["vintage", "royal"], "meaning": "Light", "popularity": "popular"},
    {"id": "josephine", "name": "Josephine", "gender": "female", "origins": ["french"], "styles": ["vintage", "elegant"], "meaning": "God will increase", "popularity": "common"},
    {"id": "florence", "name": "Florence", "gender": "female", "origins": ["latin"], "styles": ["vintage", "classic"], "meaning": "Flourishing", "popularity": "uncommon"},
    {"id": "mabel", "name": "Mabel", "gender": "female", "origins": ["latin"], "styles": ["vintage", "gentle"], "meaning": "Lovable", "popularity": "uncommon"},

    # Biblical/Religious Names
    {"id": "abraham", "name": "Abraham", "gender": "male", "origins": ["hebrew"], "styles": ["biblical", "classic"], "meaning": "Father of multitudes", "popularity": "common"},
    {"id": "ezekiel", "name": "Ezekiel", "gender": "male", "origins": ["hebrew"], "styles": ["biblical", "strong"], "meaning": "God strengthens", "popularity": "uncommon"},
    {"id": "isaiah", "name": "Isaiah", "gender": "male", "origins": ["hebrew"], "styles": ["biblical", "strong"], "meaning": "Salvation of the Lord", "popularity": "popular"},
    {"id": "jeremiah", "name": "Jeremiah", "gender": "male", "origins": ["hebrew"], "styles": ["biblical", "strong"], "meaning": "Appointed by God", "popularity": "common"},
    {"id": "micah", "name": "Micah", "gender": "neutral", "origins": ["hebrew"], "styles": ["biblical", "modern"], "meaning": "Who is like God", "popularity": "common"},
    {"id": "sarah", "name": "Sarah", "gender": "female", "origins": ["hebrew"], "styles": ["biblical", "classic"], "meaning": "Princess", "popularity": "popular"},
    {"id": "rebecca", "name": "Rebecca", "gender": "female", "origins": ["hebrew"], "styles": ["biblical", "classic"], "meaning": "To bind", "popularity": "common"},
    {"id": "rachel", "name": "Rachel", "gender": "female", "origins": ["hebrew"], "styles": ["biblical", "classic"], "meaning": "Ewe", "popularity": "common"},
    {"id": "leah", "name": "Leah", "gender": "female", "origins": ["hebrew"], "styles": ["biblical", "gentle"], "meaning": "Weary", "popularity": "common"},
    {"id": "hannah", "name": "Hannah", "gender": "female", "origins": ["hebrew"], "styles": ["biblical", "classic"], "meaning": "Grace", "popularity": "popular"},
]

# Combine with existing names, avoiding duplicates
existing_ids = {name['id'] for name in existing_names}
new_names = [name for name in additional_names if name['id'] not in existing_ids]

# Combine all names
all_names = existing_names + new_names

# Sort by name for easier browsing
all_names.sort(key=lambda x: x['name'].lower())

# Write back to file
with open('/Users/jdecker/projects/ios/name/NameMatch/Resources/names.json', 'w') as f:
    json.dump(all_names, f, indent=2)

print(f"Database expanded from {len(existing_names)} to {len(all_names)} names")
print(f"Added {len(new_names)} new names")
