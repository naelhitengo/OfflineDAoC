BEGIN TRANSACTION;

-- ============================================================================
-- 1. INSERTIONS DANS LA TABLE SPELL (Plage 401081 à 402726)
-- ============================================================================

-- --- ENDURANCE (Paladin clones -> 401081 à 401085) ---
INSERT INTO `Spell` (
    `SpellID`, `Spell_ID`, `ClientEffect`, `Icon`, `Name`, `Description`, `Target`, `Range`, `Power`, `CastTime`, 
    `Damage`, `DamageType`, `Type`, `Duration`, `Frequency`, `Pulse`, `PulsePower`, `Radius`, `RecastDelay`, 
    `ResurrectHealth`, `ResurrectMana`, `Value`, `Concentration`, `LifeDrainReturn`, `AmnesiaChance`, 
    `Message1`, `Message2`, `Message3`, `Message4`, `InstrumentRequirement`, `SpellGroup`, `EffectGroup`, 
    `SubSpellID`, `MoveCast`, `Uninterruptible`, `IsFocus`, `SharedTimerGroup`, `IsPrimary`, `IsSecondary`, 
    `AllowBolt`, `PackageID`, `TooltipId`, `LastTimeRowUpdated`
) VALUES 
(401081, '401081', 1081, 1081, 'Saga of Endurance', 'Target regenerates 1 endurance during the duration of the spell.', 'Group', 1000, 0, 0.0, 0.0, 0, 'EnduranceRegenBuff', 5, 50, 1, 2, 0, 0, 0, 0, 1.0, 0, 0, 0, 'You feel invigorated!', NULL, NULL, NULL, 0, 401081, 1001, 1000, 0, 0, 0, 0, 0, 0, 0, 'Saga_Of_Nael', 1081, '2026-11-11 00:00:00'),
(401082, '401082', 1082, 1082, 'Saga of Stamina', 'Target regenerates 2 endurance during the duration of the spell.', 'Group', 1000, 0, 0.0, 0.0, 0, 'EnduranceRegenBuff', 5, 50, 1, 5, 0, 0, 0, 0, 2.0, 0, 0, 0, 'You feel invigorated!', NULL, NULL, NULL, 0, 401081, 1001, 1000, 0, 0, 0, 0, 0, 0, 0, 'Saga_Of_Nael', 1082, '2026-11-11 00:00:00'),
(401083, '401083', 1083, 1083, 'Saga of Persistence', 'Target regenerates 3 endurance during the duration of the spell.', 'Group', 1000, 0, 0.0, 0.0, 0, 'EnduranceRegenBuff', 5, 50, 1, 7, 0, 0, 0, 0, 3.0, 0, 0, 0, 'You feel invigorated!', NULL, NULL, NULL, 0, 401081, 1001, 1000, 0, 0, 0, 0, 0, 0, 0, 'Saga_Of_Nael', 1083, '2026-11-11 00:00:00'),
(401084, '401084', 1084, 1084, 'Saga of Resilience', 'Target regenerates 4 endurance during the duration of the spell.', 'Group', 1000, 0, 0.0, 0.0, 0, 'EnduranceRegenBuff', 5, 50, 1, 11, 0, 0, 0, 0, 4.0, 0, 0, 0, 'You feel invigorated!', NULL, NULL, NULL, 0, 401081, 1001, 1000, 0, 0, 0, 0, 0, 0, 0, 'Saga_Of_Nael', 1084, '2026-11-11 00:00:00'),
(401085, '401085', 1085, 1085, 'Saga of Perseverance', 'Target regenerates 5 endurance during the duration of the spell.', 'Group', 1000, 0, 0.0, 0.0, 0, 'EnduranceRegenBuff', 5, 50, 1, 14, 0, 0, 0, 0, 5.0, 0, 0, 0, 'You feel invigorated!', NULL, NULL, NULL, 0, 401081, 1001, 1000, 0, 0, 0, 0, 0, 0, 0, 'Saga_Of_Nael', 1085, '2026-11-11 00:00:00'),

-- --- MANA / POWER (Barde clones -> 401121 à 401125) ---
(401121, '401121', 1121, 5171, 'Saga of Power', 'Target regenerates 1 extra power during the duration of the spell.', 'Group', 700, 0, 0.0, 0.0, 0, 'PowerRegenBuff', 6, 60, 1, 0, 0, 0, 0, 0, 1.0, 0, 0, 0, 'You feel a calmness come over you.', NULL, NULL, NULL, 0, 401121, 6001, 1000, 0, 0, 0, 0, 0, 0, 0, 'Saga_Of_Nael', 1121, '2026-11-11 00:00:00'),
(401122, '401122', 1122, 5172, 'Saga of Energy', 'Target regenerates 2 extra power during the duration of the spell.', 'Group', 700, 0, 0.0, 0.0, 0, 'PowerRegenBuff', 6, 60, 1, 0, 0, 0, 0, 0, 2.0, 0, 0, 0, 'You feel a calmness come over you.', NULL, NULL, NULL, 0, 401121, 6001, 1000, 0, 0, 0, 0, 0, 0, 0, 'Saga_Of_Nael', 1122, '2026-11-11 00:00:00'),
(401123, '401123', 1123, 5173, 'Saga of Clarity', 'Target regenerates 3 extra power during the duration of the spell.', 'Group', 700, 0, 0.0, 0.0, 0, 'PowerRegenBuff', 6, 60, 1, 0, 0, 0, 0, 0, 3.0, 0, 0, 0, 'You feel a calmness come over you.', NULL, NULL, NULL, 0, 401121, 6001, 1000, 0, 0, 0, 0, 0, 0, 0, 'Saga_Of_Nael', 1123, '2026-11-11 00:00:00'),
(401124, '401124', 1124, 5174, 'Saga of the Mind', 'Target regenerates 4 extra power during the duration of the spell.', 'Group', 700, 0, 0.0, 0.0, 0, 'PowerRegenBuff', 6, 60, 1, 0, 0, 0, 0, 0, 4.0, 0, 0, 0, 'You feel a calmness come over you.', NULL, NULL, NULL, 0, 401121, 6001, 1000, 0, 0, 0, 0, 0, 0, 0, 'Saga_Of_Nael', 1124, '2026-11-11 00:00:00'),
(401125, '401125', 1125, 5175, 'Saga of Empowering', 'Target regenerates 5 extra power during the duration of the spell.', 'Group', 700, 0, 0.0, 0.0, 0, 'PowerRegenBuff', 6, 60, 1, 0, 0, 0, 0, 0, 5.0, 0, 0, 0, 'You feel a calmness come over you.', NULL, NULL, NULL, 0, 401121, 6001, 1000, 0, 0, 0, 0, 0, 0, 0, 'Saga_Of_Nael', 1125, '2026-11-11 00:00:00'),

-- --- BLADETURN PULSÉ (Runemaster clones -> 402724 à 402726) ---
(402724, '402724', 2724, 2724, 'Saga of Guard', 'A ''bubble'' that absorbs the damage of a single melee hit.', 'Group', 1250, 16, 0.0, 0.0, 0, 'Bladeturn', 10, 100, 1, 40, 16, 0, 0, 0, 0.0, 0, 0, 0, 'A crystal shield covers you.', NULL, NULL, NULL, 0, 402724, 5200, 0, 0, 0, 0, 0, 0, 0, 0, 'Saga_Of_Nael', 2724, '2026-11-11 00:00:00'),
(402725, '402725', 2725, 2725, 'Saga of Barrier', 'A ''bubble'' that absorbs the damage of a single melee hit.', 'Group', 1250, 21, 0.0, 0.0, 0, 'Bladeturn', 8, 80, 1, 50, 16, 0, 0, 0, 0.0, 0, 0, 0, 'A crystal shield covers you.', NULL, NULL, NULL, 0, 402724, 5200, 0, 0, 0, 0, 0, 0, 0, 0, 'Saga_Of_Nael', 2725, '2026-11-11 00:00:00'),
(402726, '402726', 2726, 2726, 'Saga of Aegis', 'A ''bubble'' that absorbs the damage of a single melee hit.', 'Group', 1250, 28, 0.0, 0.0, 0, 'Bladeturn', 6, 60, 1, 70, 16, 0, 0, 0, 0.0, 0, 0, 0, 'A crystal shield covers you.', NULL, NULL, NULL, 0, 402724, 5200, 0, 0, 0, 0, 0, 0, 0, 0, 'Saga_Of_Nael', 2726, '2026-11-11 00:00:00');


-- ============================================================================
-- 2. INSERTIONS DANS LA TABLE LINEXSPELL (Association avec Battlesongs)
-- ============================================================================

INSERT INTO `LineXSpell` (`LineName`, `SpellID`, `Level`, `LastTimeRowUpdated`, `LineXSpell_ID`) VALUES
('Battlesongs', 401081, 2,  '2026-11-11 00:00:00', 'Battlesongs_2_2'),
('Battlesongs', 401121, 10, '2026-11-11 00:00:00', 'Battlesongs_10_2'),
('Battlesongs', 401082, 12, '2026-11-11 00:00:00', 'Battlesongs_12_2'),
('Battlesongs', 401083, 22, '2026-11-11 00:00:00', 'Battlesongs_22_3'),
('Battlesongs', 402724, 26, '2026-11-11 00:00:00', 'Battlesongs_26_2'),
('Battlesongs', 401084, 32, '2026-11-11 00:00:00', 'Battlesongs_32_2'),
('Battlesongs', 402725, 34, '2026-11-11 00:00:00', 'Battlesongs_34_2'),
('Battlesongs', 401085, 42, '2026-11-11 00:00:00', 'Battlesongs_42_2'),
('Battlesongs', 402726, 44, '2026-11-11 00:00:00', 'Battlesongs_44_2'),
('Battlesongs', 401125, 50, '2026-11-11 00:00:00', 'Battlesongs_50_3');

COMMIT;