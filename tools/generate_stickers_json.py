"""
Generate stickers.json for the Panini FIFA World Cup 2026 album.

Data extracted from https://slicice.rs/albumi/panini-fifa-world-cup-2026 on 2026-05-18.
Team order follows the official 2026 FIFA World Cup group draw (Washington DC, 2025-12-05),
which is how the Panini album orders teams.

Album spec:
- 980 total stickers, 68 foils, 48 teams.
- Specials: Panini logo "00", FWC1-FWC8 (emblems + host cities),
  FWC9-FWC19 (FIFA Museum legends), team crest (#1 of each team).
"""

import json
from pathlib import Path

TEAM_NAMES = {
    "ALG": ("Algeria",                "Alžir"),
    "ARG": ("Argentina",              "Argentina"),
    "AUS": ("Australia",              "Australija"),
    "AUT": ("Austria",                "Austrija"),
    "BEL": ("Belgium",                "Belgija"),
    "BIH": ("Bosnia and Herzegovina", "Bosna i Hercegovina"),
    "BRA": ("Brazil",                 "Brazil"),
    "CAN": ("Canada",                 "Kanada"),
    "CIV": ("Ivory Coast",            "Obala Slonovače"),
    "COD": ("DR Congo",               "DR Kongo"),
    "COL": ("Colombia",               "Kolumbija"),
    "CPV": ("Cape Verde",             "Zelenortska Ostrva"),
    "CRO": ("Croatia",                "Hrvatska"),
    "CUW": ("Curaçao",                "Kurasao"),
    "CZE": ("Czech Republic",         "Češka"),
    "ECU": ("Ecuador",                "Ekvador"),
    "EGY": ("Egypt",                  "Egipat"),
    "ENG": ("England",                "Engleska"),
    "ESP": ("Spain",                  "Španija"),
    "FRA": ("France",                 "Francuska"),
    "GER": ("Germany",                "Nemačka"),
    "GHA": ("Ghana",                  "Gana"),
    "HAI": ("Haiti",                  "Haiti"),
    "IRN": ("Iran",                   "Iran"),
    "IRQ": ("Iraq",                   "Irak"),
    "JOR": ("Jordan",                 "Jordan"),
    "JPN": ("Japan",                  "Japan"),
    "KOR": ("South Korea",            "Južna Koreja"),
    "KSA": ("Saudi Arabia",           "Saudijska Arabija"),
    "MAR": ("Morocco",                "Maroko"),
    "MEX": ("Mexico",                 "Meksiko"),
    "NED": ("Netherlands",            "Holandija"),
    "NOR": ("Norway",                 "Norveška"),
    "NZL": ("New Zealand",            "Novi Zeland"),
    "PAN": ("Panama",                 "Panama"),
    "PAR": ("Paraguay",               "Paragvaj"),
    "POR": ("Portugal",               "Portugal"),
    "QAT": ("Qatar",                  "Katar"),
    "RSA": ("South Africa",           "Južnoafrička Republika"),
    "SCO": ("Scotland",               "Škotska"),
    "SEN": ("Senegal",                "Senegal"),
    "SUI": ("Switzerland",            "Švajcarska"),
    "SWE": ("Sweden",                 "Švedska"),
    "TUN": ("Tunisia",                "Tunis"),
    "TUR": ("Türkiye",                "Turska"),
    "URU": ("Uruguay",                "Urugvaj"),
    "USA": ("United States",          "Sjedinjene Američke Države"),
    "UZB": ("Uzbekistan",             "Uzbekistan"),
}

WC_GROUPS = [
    ("A", ["MEX", "RSA", "KOR", "CZE"]),
    ("B", ["CAN", "BIH", "QAT", "SUI"]),
    ("C", ["BRA", "MAR", "HAI", "SCO"]),
    ("D", ["USA", "PAR", "AUS", "TUR"]),
    ("E", ["GER", "CUW", "CIV", "ECU"]),
    ("F", ["NED", "JPN", "SWE", "TUN"]),
    ("G", ["BEL", "EGY", "IRN", "NZL"]),
    ("H", ["ESP", "CPV", "KSA", "URU"]),
    ("I", ["FRA", "SEN", "IRQ", "NOR"]),
    ("J", ["ARG", "ALG", "AUT", "JOR"]),
    ("K", ["POR", "COD", "UZB", "COL"]),
    ("L", ["ENG", "CRO", "GHA", "PAN"]),
]

TEAMS = [(code, *TEAM_NAMES[code], gl) for gl, members in WC_GROUPS for code in members]

STICKERS_PER_TEAM = 20
SPECIAL_GROUP_CODE = "FWC"
SPECIAL_GROUP_NAME_EN = "FIFA World Cup specials"
SPECIAL_GROUP_NAME_SR = "FIFA SP specijalne sličice"


def build_stickers():
    stickers, sort_order = [], 0

    sort_order += 1
    stickers.append({
        "code": "00", "group_code": SPECIAL_GROUP_CODE,
        "group_name_en": SPECIAL_GROUP_NAME_EN, "group_name_sr_latn": SPECIAL_GROUP_NAME_SR,
        "number_in_group": 0, "is_special": True, "sort_order": sort_order,
        "subcategory_en": "Panini logo", "subcategory_sr_latn": "Panini logo",
        "wc_group": None,
    })

    for n in range(1, 9):
        sort_order += 1
        stickers.append({
            "code": f"FWC{n}", "group_code": SPECIAL_GROUP_CODE,
            "group_name_en": SPECIAL_GROUP_NAME_EN, "group_name_sr_latn": SPECIAL_GROUP_NAME_SR,
            "number_in_group": n, "is_special": True, "sort_order": sort_order,
            "subcategory_en": "Emblems & host cities",
            "subcategory_sr_latn": "Amblemi i gradovi domaćini",
            "wc_group": None,
        })

    for n in range(9, 20):
        sort_order += 1
        stickers.append({
            "code": f"FWC{n}", "group_code": SPECIAL_GROUP_CODE,
            "group_name_en": SPECIAL_GROUP_NAME_EN, "group_name_sr_latn": SPECIAL_GROUP_NAME_SR,
            "number_in_group": n, "is_special": True, "sort_order": sort_order,
            "subcategory_en": "FIFA Museum — Champion Legends",
            "subcategory_sr_latn": "FIFA Museum — legende šampiona",
            "wc_group": None,
        })

    for code, name_en, name_sr, wc_group in TEAMS:
        for n in range(1, STICKERS_PER_TEAM + 1):
            sort_order += 1
            is_crest = (n == 1)
            stickers.append({
                "code": f"{code}{n}", "group_code": code,
                "group_name_en": name_en, "group_name_sr_latn": name_sr,
                "number_in_group": n, "is_special": is_crest, "sort_order": sort_order,
                "subcategory_en": "Team crest" if is_crest else "Player",
                "subcategory_sr_latn": "Grb reprezentacije" if is_crest else "Igrač",
                "wc_group": wc_group,
            })

    return stickers


def main():
    stickers = build_stickers()
    total = len(stickers)
    foils = sum(1 for s in stickers if s["is_special"])
    assert total == 980, f"Expected 980 stickers, got {total}"
    assert foils == 68, f"Expected 68 foil stickers, got {foils}"
    assert len(TEAMS) == 48, f"Expected 48 teams, got {len(TEAMS)}"

    wc_groups_out = [{"letter": l, "team_codes": m} for l, m in WC_GROUPS]

    album = {
        "album": {
            "id": "panini-fifa-world-cup-2026",
            "name_en": "Panini FIFA World Cup 2026",
            "name_sr_latn": "Panini FIFA Svetsko prvenstvo 2026",
            "publisher": "Panini",
            "year": 2026,
            "total_stickers": total,
            "foil_count": foils,
            "team_count": len(TEAMS),
            "source": "https://slicice.rs/albumi/panini-fifa-world-cup-2026",
            "extracted_on": "2026-05-18",
            "team_order": "wc-2026-group-draw",
            "wc_groups": wc_groups_out,
        },
        "stickers": stickers,
    }

    out_path = Path(__file__).resolve().parent.parent / "data" / "stickers.json"
    out_path.parent.mkdir(parents=True, exist_ok=True)
    with open(out_path, "w", encoding="utf-8") as f:
        json.dump(album, f, ensure_ascii=False, indent=2)

    print(f"Wrote {out_path}")
    print(f"  total stickers : {total}")
    print(f"  foil stickers  : {foils}")
    print(f"  teams          : {len(TEAMS)}")


if __name__ == "__main__":
    main()
