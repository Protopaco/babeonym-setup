INSERT INTO language_region_bridge_staging (language_id, region_id, date_created)
VALUES
  -- Africa — West Africa (11)
  (75, 11, NOW()),   -- Yoruba
  (203,11, NOW()),   -- Akan
  (205,11, NOW()),   -- Bemba
  (206,11, NOW()),   -- Igbo
  (207,11, NOW()),   -- Hausa

  -- Africa — East Africa (12)
  (3, 12, NOW()),    -- Amharic
  (208,12, NOW()),   -- Somali
  (63,12, NOW()),    -- Swahili

  -- Africa — Southern & Central Africa (13)
  (1, 13, NOW()),    -- Afrikaans
  (204,13, NOW()),   -- Shona
  (72,13, NOW()),    -- Zulu

  -- Europe — British Isles (20)
  (18,20, NOW()),    -- English
  (197,20, NOW()),   -- Irish
  (198,20, NOW()),   -- Welsh
  (199,20, NOW()),   -- Scottish Gaelic

  -- Europe — Northern Europe (21)
  (16,21, NOW()),    -- Danish
  (19,21, NOW()),    -- Estonian
  (21,21, NOW()),    -- Finnish
  (31,21, NOW()),    -- Icelandic
  (50,21, NOW()),    -- Norwegian
  (64,21, NOW()),    -- Swedish

  -- Europe — Western Europe (22)
  (7, 22, NOW()),    -- Basque
  (12,22, NOW()),    -- Catalan
  (17,22, NOW()),    -- Dutch
  (22,22, NOW()),    -- French
  (23,22, NOW()),    -- Galician
  (25,22, NOW()),    -- German
  (200,22, NOW()),   -- Breton

  -- Europe — Southern Europe (23)
  (33,23, NOW()),    -- Italian
  (26,23, NOW()),    -- Greek
  (62,23, NOW()),    -- Spanish
  (53,23, NOW()),    -- Portuguese

  -- Europe — Central Europe (24)
  (15,24, NOW()),    -- Czech
  (30,24, NOW()),    -- Hungarian
  (52,24, NOW()),    -- Polish
  (60,24, NOW()),    -- Slovak
  (56,24, NOW()),    -- Romansh

  -- Europe — Eastern Europe (25)
  (8, 25, NOW()),    -- Belarusian
  (42,25, NOW()),    -- Latvian
  (43,25, NOW()),    -- Lithuanian
  (57,25, NOW()),    -- Russian
  (69,25, NOW()),    -- Ukrainian

  -- Europe — Balkans (26)
  (2, 26, NOW()),    -- Albanian
  (10,26, NOW()),    -- Bulgarian
  (14,26, NOW()),    -- Croatian
  (44,26, NOW()),    -- Macedonian
  (55,26, NOW()),    -- Romanian
  (58,26, NOW()),    -- Serbian
  (61,26, NOW()),    -- Slovenian

  -- Europe — Pan-European (27)
  (209,27, NOW()),   -- Latin
  (196,27, NOW()),   -- Yiddish

  -- Asia — West Asia & Caucasus (30)
  (4, 30, NOW()),    -- Arabic
  (5, 30, NOW()),    -- Armenian
  (6, 30, NOW()),    -- Azerbaijani
  (24,30, NOW()),    -- Georgian
  (28,30, NOW()),    -- Hebrew
  (51,30, NOW()),    -- Persian
  (68,30, NOW()),    -- Turkish
  (210,30, NOW()),   -- Kurdish

  -- Asia — Central Asia (31)
  (37,31, NOW()),    -- Kazakh
  (40,31, NOW()),    -- Kyrgyz
  (202,31, NOW()),   -- Uzbek

  -- Asia — South Asia (32)
  (9, 32, NOW()),    -- Bengali
  (27,32, NOW()),    -- Gujarati
  (29,32, NOW()),    -- Hindi
  (36,32, NOW()),    -- Kannada
  (46,32, NOW()),    -- Malayalam
  (47,32, NOW()),    -- Marathi
  (49,32, NOW()),    -- Nepali
  (54,32, NOW()),    -- Punjabi
  (65,32, NOW()),    -- Tamil
  (66,32, NOW()),    -- Telugu
  (70,32, NOW()),    -- Urdu
  (201,32, NOW()),   -- Dzongkha
  (59,32, NOW()),    -- Sinhala

  -- Asia — East Asia (33)
  (13,33, NOW()),    -- Chinese
  (34,33, NOW()),    -- Japanese
  (39,33, NOW()),    -- Korean
  (48,33, NOW()),    -- Mongolian

  -- Asia — Southeast Asia (34)
  (11,34, NOW()),    -- Burmese
  (20,34, NOW()),    -- Filipino
  (32,34, NOW()),    -- Indonesian
  (35,34, NOW()),    -- Javanese
  (38,34, NOW()),    -- Khmer
  (41,34, NOW()),    -- Lao
  (45,34, NOW()),    -- Malay
  (67,34, NOW()),    -- Thai
  (71,34, NOW()),    -- Vietnamese

  -- Oceania — Australia & New Zealand (40)
  (74,40, NOW()),    -- Māori

  -- Oceania — Polynesia (41)
  (214,41, NOW()),   -- Hawaiian
  (215,41, NOW()),   -- Samoan

  -- Oceania — Melanesia (42)
  (73,42, NOW()),    -- Fijian

  -- Americas — North America (50)
  (211,50, NOW()),   -- Haitian Creole

  -- Americas — South America (52)
  (212,52, NOW()),   -- Guarani
  (213,52, NOW())    -- Quechua
ON CONFLICT (language_id, region_id) DO NOTHING;
