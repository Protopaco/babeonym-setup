INSERT INTO culture_region_bridge_staging (culture_id, region_id, date_created)
VALUES

  -- Africa — North Africa (10)
  (8, 10, NOW()),    -- Moroccan
  (10,10, NOW()),    -- Tunisian
  (22,10, NOW()),    -- Egyptian
  (23,10, NOW()),    -- Ancient Egyptian
  (21,10, NOW()),    -- Coptic

  -- Africa — West Africa (11)
  (1, 11, NOW()),    -- Akan
  (2, 11, NOW()),    -- Ashanti
  (5, 11, NOW()),    -- Hausa
  (6, 11, NOW()),    -- Igbo
  (7, 11, NOW()),    -- Yoruba
  (15,11, NOW()),    -- Nigerian (origin)
  (17,11, NOW()),    -- Senegalese

  -- Africa — East Africa (12)
  (4, 12, NOW()),    -- Ethiopian
  (13,12, NOW()),    -- Kenyan
  (18,12, NOW()),    -- Somali

  -- Africa — Southern & Central Africa (13)
  (3, 13, NOW()),    -- Shona
  (9, 13, NOW()),    -- South African
  (11,13, NOW()),    -- Botswana
  (12,13, NOW()),    -- Democratic Republic of the Congo
  (14,13, NOW()),    -- Namibian
  (16,13, NOW()),    -- Zambian
  (19,13, NOW()),    -- Bemba
  (20,13, NOW()),    -- African-American (diaspora root)

  -- Asia — West Asia & Caucasus (30)
  (24,30, NOW()),    -- Afghan
  (25,30, NOW()),    -- Azerbaijani
  (26,30, NOW()),    -- Persian
  (27,30, NOW()),    -- Iranian
  (28,30, NOW()),    -- Armenian
  (29,30, NOW()),    -- Mandaean
  (31,30, NOW()),    -- Turkish
  (34,30, NOW()),    -- Jewish

  -- Asia — Central Asia (31)
  (32,31, NOW()),    -- Tatar
  (33,31, NOW()),    -- Bashkir
  (55,31, NOW()),    -- Kazakh
  (56,31, NOW()),    -- Tajikistani
  (57,31, NOW()),    -- Uzbekistani

  -- Asia — South Asia (32)
  (35,32, NOW()),    -- Hindu
  (36,32, NOW()),    -- Indian
  (37,32, NOW()),    -- Gujarati
  (38,32, NOW()),    -- Tamil
  (39,32, NOW()),    -- Telugu
  (40,32, NOW()),    -- Urdu
  (41,32, NOW()),    -- Nepalese
  (42,32, NOW()),    -- Pakistani
  (43,32, NOW()),    -- Sinhalese
  (44,32, NOW()),    -- Bangladeshi

  -- Asia — East Asia (33)
  (45,33, NOW()),    -- Chinese
  (46,33, NOW()),    -- Japanese
  (47,33, NOW()),    -- Korean
  (48,33, NOW()),    -- Mongolian
  (30,33, NOW()),    -- Uyghur (East Asia placement)

  -- Asia — Southeast Asia (34)
  (49,34, NOW()),    -- Thai
  (50,34, NOW()),    -- Vietnamese
  (51,34, NOW()),    -- Malaysian
  (52,34, NOW()),    -- Indonesian
  (53,34, NOW()),    -- Filipino
  (54,34, NOW()),    -- Formosan

  -- Oceania — Australia & New Zealand (40)
  (60,40, NOW()),    -- Māori
  (63,40, NOW()),    -- Australian

  -- Oceania — Polynesia (41)
  (59,41, NOW()),    -- Polynesian
  (61,41, NOW()),    -- Samoan
  (62,41, NOW()),    -- Tongan

  -- Oceania — Melanesia (42)
  (58,42, NOW()),    -- Fijian

  -- Americas — Caribbean (51)
  (64,51, NOW()),    -- Trinidadian

  -- Europe — British Isles (20)
  (65,20, NOW()),    -- Celtic
  (66,20, NOW()),    -- British Isles
  (83,20, NOW()),    -- English
  (94,20, NOW()),    -- Irish
  (108,20, NOW()),   -- Scottish
  (109,20, NOW()),   -- Scottish Gaelic
  (116,20, NOW()),   -- Welsh
  (117,20, NOW()),   -- Manx

  -- Europe — Northern Europe (21)
  (68,21, NOW()),    -- Scandinavian
  (81,21, NOW()),    -- Danish
  (84,21, NOW()),    -- Estonian
  (85,21, NOW()),    -- Faroese
  (86,21, NOW()),    -- Finnish
  (93,21, NOW()),    -- Icelandic
  (102,21, NOW()),   -- Norwegian

  -- Europe — Western Europe (22)
  (72,22, NOW()),    -- Basque
  (76,22, NOW()),    -- Breton
  (78,22, NOW()),    -- Catalan
  (82,22, NOW()),    -- Dutch
  (87,22, NOW()),    -- French
  (88,22, NOW()),    -- Galician
  (90,22, NOW()),    -- German
  (114,22, NOW()),   -- Swiss
  (118,22, NOW()),   -- Frisian

  -- Europe — Southern Europe (23)
  (91,23, NOW()),    -- Greek
  (95,23, NOW()),    -- Italian
  (104,23, NOW()),   -- Portuguese
  (113,23, NOW()),   -- Spanish
  (107,23, NOW()),   -- Sammarinese

  -- Europe — Central Europe (24)
  (80,24, NOW()),    -- Czech
  (92,24, NOW()),    -- Hungarian
  (103,24, NOW()),   -- Polish
  (111,24, NOW()),   -- Slovak
  (114,24, NOW()),   -- Swiss (alt regional overlap)

  -- Europe — Eastern Europe (25)
  (69,25, NOW()),    -- Slavic
  (73,25, NOW()),    -- Belarusian
  (96,25, NOW()),    -- Latvian
  (97,25, NOW()),    -- Lithuanian
  (100,25, NOW()),   -- Moldovan
  (106,25, NOW()),   -- Russian
  (115,25, NOW()),   -- Ukrainian

  -- Europe — Balkans (26)
  (70,26, NOW()),    -- Albanian
  (71,26, NOW()),    -- Aromanian
  (74,26, NOW()),    -- Bosniak
  (75,26, NOW()),    -- Bosnian
  (77,26, NOW()),    -- Bulgarian
  (79,26, NOW()),    -- Croatian
  (98,26, NOW()),    -- Macedonian
  (99,26, NOW()),    -- Megleno-Romanian
  (101,26, NOW()),   -- Montenegrin
  (105,26, NOW()),   -- Romanian
  (110,26, NOW()),   -- Serbian
  (112,26, NOW())    -- Slovene

ON CONFLICT (culture_id, region_id) DO NOTHING;
