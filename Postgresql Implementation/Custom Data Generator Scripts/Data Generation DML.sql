-- Update member customers, who are not in the provided set of Id, in terms of the branch that they live nearby.
UPDATE "MemberCustomer"
SET "liveNearBranchId" = (SELECT "branchId"
                          FROM "Branch"
                          WHERE "memberCustomerId" = "memberCustomerId"
                          ORDER BY (
                                       SELECT (SELECT random() WHERE "g" = "g" AND "branchId" = "branchId")
                                       FROM generate_series(1, 10) "g"
                                       LIMIT 1
                                   )
                          LIMIT 1)
WHERE "memberCustomerId" NOT IN (
                                 '5d6ea576-5d1a-4de6-8531-f28528fd598a',
                                 '56791212-598f-4b7d-805e-5e7ac69d2f88',
                                 '7f331fbb-4766-4eeb-82d9-c40af58320be',
                                 '07ad35c6-cf7c-43e0-af15-a88d80ad9802',
                                 'c3383057-da58-4814-a1b6-39c97ca67740',
                                 '72a910bd-617b-4fed-93a1-6e10fbae5f95',
                                 'b7a57961-b4ae-46f3-bf63-e20960e9a16b',
                                 '6367080e-ffae-48aa-9581-beb0e2b6c969'
    );

-- Randomly Update billing information with member-customer-related information such as points, its expiration as well as the member Id.
UPDATE "Billing" "A"
SET "pointExpirationTime"      = '1 year'::INTERVAL,
    "pointReceived"            = floor(random() * (1000 - 100 + 1) + 100),
    "involvedMemberCustomerId" = (
        SELECT "memberCustomerId"
        FROM "MemberCustomer"
        WHERE "A"."billingId" = "A"."billingId"
        ORDER BY (SELECT (SELECT random() WHERE "g" = "g" AND "A"."billingId" = "A"."billingId")
                  FROM generate_series(1, 10) "g"
                  LIMIT 1)
        LIMIT 1
    )
WHERE "timePaid" IS NOT NULL
  AND random() < 0.2;


--  Check for member who has involvedMemberCustomerId
SELECT *
FROM "Billing"
WHERE "involvedMemberCustomerId" IS NOT NULL;

-- Update involvedMemberCustomerId with random MemberCustomerId
UPDATE "Billing" "A"
SET "involvedMemberCustomerId" = (
    SELECT "memberCustomerId"
    FROM "MemberCustomer"
    WHERE "A"."billingId" = "A"."billingId"
    ORDER BY (SELECT (SELECT random() WHERE "g" = "g" AND "memberCustomerId" = "memberCustomerId")
              FROM generate_series(1, 10) "g"
              LIMIT 1)
    LIMIT 1
)
WHERE "involvedMemberCustomerId" IS NOT NULL;

-- Randomly assign member customers to billings
-- This WILL NOT WORK. ALL ROWS WILL HAVE a randomly identical "involvedMemberCustomerId" value!!
UPDATE "Billing" "A"
SET "involvedMemberCustomerId" = (
    SELECT "memberCustomerId"
    FROM "MemberCustomer"
    ORDER BY random()
    LIMIT 1
)
WHERE "involvedMemberCustomerId" IS NOT NULL;

-- Generate employee email based on their full name. When the email is duplicate (violates unique constraint), we will count number up by 1.
SELECT CASE
           WHEN "rowNo" = 1 THEN concat("email", '@sizzler.co.th')
           ELSE concat(concat("email", "rowNo", '@sizzler.co.th')) END,
       "employeeId"
FROM (
         SELECT concat(replace(lower("firstname"), ' ', '_'), '.', substr(lower("surname"), 1, 3)) "email",
                row_number() OVER (PARTITION BY concat(replace(lower("firstname"), ' ', '_'), '.',
                                                       substr(lower("surname"), 1, 3)))            "rowNo",
                "employeeId"

         FROM "Employee"
     ) "X";


-- Infer the email address of an employee from his/her first name and surname.
SELECT DISTINCT concat(replace(lower("firstname"), ' ', '_'), '.', substr(lower("surname"), 1, 3), '@sizzler.co.th'),
                count(*)
FROM "Employee"
GROUP BY concat(replace(lower("firstname"), ' ', '_'), '.', substr(lower("surname"), 1, 3), '@sizzler.co.th');

-- Update EMPLOYEE data such as email, educationLevelId, provinceId
UPDATE "Employee" "A"
SET "email"            = (
    SELECT CASE
               WHEN "rowNo" = 1 THEN concat("email", '@sizzler.co.th')
               ELSE concat(concat("email", "rowNo", '@sizzler.co.th')) END
    FROM (
             SELECT concat(replace(lower("firstname"), ' ', '_'), '.', substr(lower("surname"), 1, 3)) "email",
                    row_number() OVER (PARTITION BY concat(replace(lower("firstname"), ' ', '_'), '.',
                                                           substr(lower("surname"), 1, 3)))            "rowNo",
                    "employeeId"

             FROM "Employee"
             WHERE concat(replace(lower("firstname"), ' ', '_'), '.', substr(lower("surname"), 1, 3)) =
                   concat(replace(lower("A"."firstname"), ' ', '_'), '.', substr(lower("A"."surname"), 1, 3))
         ) "X"
    WHERE "A"."employeeId" = "X"."employeeId"
),
    "educationLevelId" = (
        SELECT "educationLevelId"
        FROM "EducationLevelRef"
        WHERE "A"."employeeId" = "A"."employeeId"
        ORDER BY (SELECT (SELECT random() WHERE "g" = "g" AND "educationLevelId" = "educationLevelId")
                  FROM generate_series(1, 10) "g"
                  LIMIT 1)
        LIMIT 1
    ),
    "provinceId"       = (
        SELECT "Province"."provinceId"
        FROM "Province"
        WHERE "A"."employeeId" = "A"."employeeId"
        ORDER BY (SELECT (SELECT random() WHERE "g" = "g" AND "provinceId" = "provinceId")
                  FROM generate_series(1, 10) "g"
                  LIMIT 1)
        LIMIT 1
    );


-- Update Employee's gender by inspecting the his/her first name.
UPDATE "Employee"
SET "gender" = (
    SELECT CASE
               WHEN "firstname" IN
                    ('Aat', 'Aawut', 'Adirake', 'Akkanee', 'Akkarat', 'Alak', 'Amnuay', 'Anada', 'Ananada', 'Ananda',
                     'Annan', 'Anon', 'Anuia', 'Anuman', 'Anurak', 'Anuthat', 'Apichart', 'Aran', 'Aroon', 'Arthit',
                     'Ashwin', 'Asnee', 'Athiti', 'Atid', 'Badinton', 'Baharn', 'Bahn', 'Bandasak', 'Banjong', 'Banlop',
                     'Banlue', 'Bannarasee', 'Bannarot', 'Bannasorn', 'Banthorn', 'Banwithit', 'Banyat', 'Banyong',
                     'Bapit',
                     'Barinai', 'Barinot', 'Baritharn', 'Baroma', 'Baveethran', 'Bawornnon', 'Bawornthath', 'Bhakdi',
                     'Bhichai', 'Bhumipol', 'Bin', 'Bodesta', 'Boon-Mee', 'Boon-Nam', 'Boon-mee', 'Boon-nam', 'Boonchu',
                     'Boonma', 'Boonpipob', 'Boontung', 'Brosong', 'Buangam', 'Budin', 'Bunbongkarn', 'Bunkit',
                     'Bunyakorn',
                     'Bunyapoo', 'Buppakorn', 'Burapol', 'Burimas', 'Burin', 'Burit', 'Burut', 'Cha', 'Chai',
                     'Chai Son',
                     'Chairat', 'Chaisai', 'Chaiya', 'Chaiyanuchit', 'Chaiyo', 'Chakan', 'Chakrabandhu', 'Chakri',
                     'Chalerm', 'Chalermchai', 'Chaloem', 'Chalong', 'Changsai', 'Channarong', 'Chanthara', 'Chao Fah',
                     'Chao-Tak', 'Chao-khun-sa', 'Chao-tak', 'Chaovalit', 'Chaowas', 'Charn Chai', 'Charnchai',
                     'Charoen',
                     'Charoensom', 'Charong', 'Chatalerm', 'Chatchalerm', 'Chatchawee', 'Chatchom', 'Chatichai',
                     'Chatri',
                     'Chaturon', 'Chavalit', 'Chayan', 'Chayond', 'Cheewaket', 'Chennoi', 'Chermsak', 'Chesda', 'Chet',
                     'Chetta', 'Chinawoot', 'Chiradet', 'Chomanan', 'Chompoo', 'Chon', 'Chongrak', 'Choochai',
                     'Choonhavan',
                     'Choonhavon', 'Chuachai', 'Chuan', 'Chuanchen', 'Chuchai', 'Chuia', 'Chula', 'Chulalongkorn',
                     'Chulamai', 'Churai', 'Chuthamani', 'Daeng', 'Damrong', 'Danai', 'Danit', 'Danunan', 'Danusorn',
                     'Daran', 'Daranpob', 'Darin', 'Decha', 'Deng', 'Denpoom', 'Dentharonee', 'Dhipyamongkol', 'Dilok',
                     'Diloktham', 'Disakorn', 'Disnadda', 'Disorn', 'Ditaka', 'Dithakar', 'Ditt', 'Dok', 'Dok rak',
                     'Dolrit', 'Dolsook', 'Dorn', 'Duchanee', 'Emjaroen', 'Erawan', 'Fah', 'Fufanwonich', 'Gee',
                     'Hainad',
                     'Hanuman', 'Hiran', 'Intradit', 'Ittiporn', 'Jaidee', 'Jao', 'Jarunsuk', 'Jatukamramthep',
                     'Jaturun',
                     'Jayavarman', 'Jessupha', 'Jettrin', 'Jirasak', 'Jutharat', 'Kaan', 'Kaandit', 'Kacha',
                     'Kamalakorn',
                     'Kamalanan', 'Kamalat', 'Kamik', 'Kamnan', 'Kamolpob', 'Kamolpoo', 'Kamut', 'Kan', 'Kananat',
                     'Kanaporn', 'Kanasanan', 'Kanda', 'Kandad', 'Kanin', 'Kanisorn', 'Kankawee', 'Kanok', 'Kanokpol',
                     'Kantapol', 'Kantapong', 'Kantayot', 'Kantharat', 'Kanthee', 'Kanthorn', 'Kantinan', 'Kantitat',
                     'Kantsak', 'Kantsom', 'Kanut', 'Kapp', 'Karan', 'Karanyapat', 'Karin', 'Karit', 'Karmatha', 'Karn',
                     'Karom', 'Kasan', 'Kasem', 'Kasemchai', 'Kasemsan', 'Kasidid', 'Kasin', 'Kasom', 'Kate',
                     'Kathawut',
                     'Kavi', 'Kawee', 'Kawin', 'Kawinpob', 'Keerati', 'Keetau', 'Khakanang', 'Khanti', 'Khattiya',
                     'Khem',
                     'Khemanan', 'Khematat', 'Khematin', 'Khemin', 'Khemkhaeng', 'Khun', 'Khunpol', 'Khunsoek', 'Kiet',
                     'Kiettinonnapat', 'Kiettisuk', 'Kimhan', 'Kirakorn', 'Kit', 'Kitsakan', 'Kitsakorn', 'Kitt',
                     'Kitti',
                     'Kittibun', 'Kittichai', 'Kittichat', 'Kittikawin', 'Kittikchorn', 'Kittikorn', 'Kittinai',
                     'Kittinan',
                     'Kittipob', 'Kittipon', 'Kittipoom', 'Kittiporn', 'Kittipot', 'Kittisak', 'Kittitat', 'Kittithorn',
                     'Kittiwin', 'Kla', 'Kla Han', 'Klaew Kla', 'Klahan', 'Kob', 'Kob Chai', 'Kob Khun', 'Kob Sinn',
                     'Kob Sook', 'Kolatee', 'Komalat', 'Komn', 'Kongbej', 'Kongkidakorn', 'Kongpob', 'Kongsampong',
                     'Konthee', 'Konthorn', 'Koradol', 'Korakod', 'Koran', 'Korapoo', 'Korasut', 'Koratak', 'Korn',
                     'Kornballop', 'Kot', 'Kovit', 'Krairawee', 'Kraisee', 'Kraisingha', 'Kraiwin', 'Krarayoon',
                     'Kriang Krai', 'Kriang Sak', 'Kriangsak', 'Kriengsak', 'Kris', 'Krisik', 'Krit', 'Krita',
                     'Kritsada',
                     'Krittameth', 'Krittanoo', 'Krittapat', 'Krittapot', 'Krittayot', 'Krittin', 'Krittinai',
                     'Krittithee',
                     'Krom-Luang', 'Krom-luang', 'Kukrit', 'Kulit', 'Kulpat', 'Kulthorn', 'Kunach', 'Kunanan', 'Kunn',
                     'Kunnthorn', 'Kusa', 'Kusum', 'Kutsa', 'Kwanchai', 'Kwanjai', 'Lamom', 'Lamon', 'Lap', 'Leekpai',
                     'Leekpie', 'Lek', 'Loesan', 'Luk', 'Maha', 'Mahidol', 'Malian', 'Maliwan', 'Manee', 'Manitho',
                     'Mee',
                     'Mee Noi', 'Mengrai', 'Metananda', 'Mok', 'Mokkhavesa', 'Molthisok', 'Mongkut', 'Monyakul', 'Muoi',
                     'Nadee', 'Nai-Thim', 'Nai-thim', 'Nak', 'Nakaret', 'Nakarin', 'Nang-Klao', 'Nang-klao',
                     'Nanthapob',
                     'Nanthayot', 'Nanthit', 'Nantin', 'Nantipat', 'Nantiworn', 'Napan', 'Napat', 'Napatthorn', 'Napon',
                     'Narai', 'Naresuan', 'Naris', 'Narisa', 'Narong', 'Narongrit', 'Narongwit', 'Naruerong',
                     'Naruesorn',
                     'Nat', 'Natee', 'Nathawat', 'Nattadanai', 'Nattakamol', 'Nattakan', 'Nattanai', 'Nattanan',
                     'Nattanon',
                     'Nattapat', 'Nattapon', 'Nattaron', 'Nattasit', 'Nattasom', 'Nattasut', 'Nattawat', 'Nattaworn',
                     'Nattayot', 'Natthapong', 'Natthawut', 'Nawanthorn', 'Nawat', 'Nawatkorn', 'Nawin', 'Nekk', 'Net',
                     'Netithorn', 'Netiwit', 'Ngam', 'Ngoen', 'Nibun', 'Nikom', 'Nikon', 'Nimman', 'Nimmit', 'Nintau',
                     'Nipaat', 'Nipat', 'Niphon', 'Nipit', 'Nipitpon', 'Nipon', 'Nipun', 'Niran', 'Nirawit', 'Nirin',
                     'Nirund', 'Nissorn', 'Nit', 'Nithan', 'Nithikorn', 'Nithit', 'Nithoon', 'Nitithorn', 'Nitthan',
                     'Nitthon', 'Niwat', 'Niwit', 'Niyom', 'Nodthakorn', 'Noi', 'Non', 'Nongchai', 'Nongkhai',
                     'Nonpawit',
                     'Nontapan', 'Nontawat', 'Nontiyut', 'Nopjira', 'Noppadon', 'Noppadorn', 'Noppakorn', 'Noppasin',
                     'Noppathee', 'Noppawin', 'Norachai', 'Norrapan', 'Norrapon', 'Norrathee', 'Norrawee', 'Norraworn',
                     'Nuananong', 'Nuengnimman', 'Nugoon', 'Nui', 'Nung', 'Nuta-Laya', 'Nuta-laya', 'Obb', 'Olan',
                     'Osathee', 'Othong', 'Paan', 'Paanthath', 'Pairat', 'Pairote', 'Paitoon', 'Pakhdi', 'Palat',
                     'Pamut',
                     'Pan', 'Panas', 'Panat', 'Panithi', 'Pann', 'Pannathath', 'Pannathorn', 'Pannawat', 'Panthorn',
                     'Panyarachun', 'Papangkorn', 'Paparn', 'Papawin', 'Papob', 'Papon', 'Paponsan', 'Paponthanai',
                     'Paponthee', 'Paradorn', 'Parama', 'Paraman', 'Paramat', 'Paramendr', 'Paranat', 'Parat', 'Parin',
                     'Parit', 'Parnchand', 'Paron', 'Parun', 'Pasan', 'Pasat', 'Pasut', 'Pathanin', 'Pathapee',
                     'Pathit',
                     'Patipon', 'Patt', 'Pattama', 'Pawaret', 'Pawarit', 'Pawaritsorn', 'Pawarut', 'Pawat', 'Paween',
                     'Pawin', 'Pawit', 'Pawornruj', 'Payut', 'Pet', 'Petch', 'Petchara', 'Petchra', 'Phaibun',
                     'Phaithoon',
                     'Phanumas', 'Phara', 'Phassakorn', 'Phatra', 'Phatson', 'Phet', 'Phichai', 'Phichit', 'Phinihan',
                     'Phisan', 'Phongsak', 'Phraisong', 'Phrom-Borirak', 'Phrom-borirak', 'Phueng', 'Phuri', 'Phya',
                     'Pichai', 'Pichit', 'Pidok', 'Pira', 'Piya', 'Piyabutr', 'Piyapat', 'Piyapon', 'Piyatat',
                     'Piyawat',
                     'Ponggool', 'Pongkun', 'Pongpanet', 'Pongpob', 'Pongrit', 'Pongsom', 'Pongtham', 'Pra', 'Pracha',
                     'Prachuab', 'Prakit', 'Prakorb', 'Pralop', 'Praman', 'Pramanat', 'Pramod', 'Pramoj', 'Pramon',
                     'Pran',
                     'Pranai', 'Pranon', 'Pranop', 'Prapaan', 'Prapan', 'Prapawit', 'Prasong', 'Prasopchai', 'Pravat',
                     'Praves', 'Prawanwit', 'Prawee', 'Praween', 'Praya', 'Prayut', 'Preet', 'Prem', 'Pricha', 'Prid',
                     'Prisna', 'Pritsadee', 'Pritsanee', 'Proi', 'Pu', 'Pu Yai Bahn', 'Puenthai', 'Puran', 'Puttipat',
                     'Rachotai', 'Raegan', 'Rajanon', 'Rak', 'Rama', 'Ramkamhaeng', 'Rand', 'Rangsan', 'Rangsiman',
                     'Ratanankorn', 'Ratri', 'Ratsami', 'Rawee', 'Ritthirong', 'Rom Ran', 'Ronnapee', 'Ruang Rit',
                     'Ruang Sak', 'Runrot', 'Sajja', 'Sakchai', 'Sakda', 'Sampan', 'Samyan', 'San''ya', 'Sanan',
                     'Sanouk',
                     'Santichai', 'Sanun', 'Sap', 'Saranyu', 'Sarathoon', 'Sarawong', 'Sarawut', 'Sarit', 'Sarut',
                     'Sataheep', 'Satayu', 'Satra', 'Satrud', 'Savit', 'Sawai', 'Sawat', 'Seni', 'Seri', 'Si', 'Siam',
                     'Siddhi', 'Sin', 'Singnum', 'Sinn', 'Snoh', 'Som', 'Som Phon', 'Som Phong', 'Sombat', 'Somchai',
                     'Somchair', 'Somchith', 'Somdej', 'Somdet-Ong-Yai', 'Somdet-ong-yai', 'Somdetch', 'Sompron',
                     'Somsak',
                     'Somwang', 'Son', 'Son Chai', 'Sonchai', 'Songgram', 'Songpob', 'Songpole', 'Songwut', 'Soo',
                     'Sook',
                     'Sophuk', 'Srimuang', 'Staporn', 'Su', 'Su Suk', 'Suchin', 'Sud', 'Sud Saming', 'Suda', 'Sudarak',
                     'Suk', 'Sulak', 'Sum', 'Sumatra', 'Sunan', 'Sundaravej', 'Suntarankul', 'Sunti', 'Sunya', 'Sup',
                     'Suphatra', 'Suphayok', 'Supoj', 'Supp', 'Supsampantuwongse', 'Sura', 'Surasak', 'Surat', 'Surin',
                     'Suriwongse', 'Suriyawong', 'Sutep', 'Suthep', 'Suttipong', 'Taan', 'Tadpol', 'Tadpong',
                     'Tadsuang',
                     'Tadthep', 'Tadthon', 'Taeng', 'Tai', 'Tak', 'Tak-Sin', 'Tak-sin', 'Takdanai', 'Tam', 'Tamnurath',
                     'Tanakrit', 'Tangpanitharn', 'Tanit', 'Tanupat', 'Tanusorn', 'Tanutam', 'Tapp', 'Tappasan',
                     'Taran',
                     'Tarrin', 'Tassapon', 'Tau', 'Taweepak', 'Taweerat', 'Tayakorn', 'Tayut', 'Teepakorn', 'Teepth',
                     'Teera', 'Tep', 'Teptath', 'Thahan', 'Thaklaew', 'Thaksin', 'Tham-Boon', 'Tham-boon', 'Thammanit',
                     'Thammaraja', 'Thammasorn', 'Thampapon', 'Thampon', 'Thamwat', 'Thanaboon', 'Thanadol', 'Thanadun',
                     'Thanalop', 'Thanandorn', 'Thananop', 'Thanapon', 'Thanapoom', 'Thanarat', 'Thanat', 'Thanatat',
                     'Thanawan', 'Thanawat', 'Thanawin', 'Thanayut', 'Thanee', 'Thanetpol', 'Thanid', 'Thanik',
                     'Thanin',
                     'Thanit', 'Thanom', 'Thanut', 'Thanwa', 'Thanya', 'Thapthim', 'Tharathep', 'Tharathorn', 'Tharit',
                     'Tharn', 'Thath', 'Thawan', 'Thawanya', 'Thawi', 'Thawin', 'Thawit', 'Thayot', 'Theema', 'Theepob',
                     'Theera', 'Theeradon', 'Theerameth', 'Theeranai', 'Theeranop', 'Theerapat', 'Theerapatpong',
                     'Theerat',
                     'Theeratham', 'Theeratorn', 'Theerit', 'Theerut', 'Theesud', 'Theethath', 'Thinnakorn', 'Thipok',
                     'Thira', 'Thirakun', 'Thiramon', 'Thiranai', 'Thiraput', 'Thirdpong', 'Thith', 'Thiti', 'Thitipan',
                     'Thitisan', 'Thitisorn', 'Thitiwat', 'Thitiwut', 'Thong Daeng', 'Thong Di', 'Thong Kon',
                     'Thong Thaeng', 'Thongchai', 'Thongkon', 'Thoranan', 'Thorm', 'Thorn', 'Thornthep', 'Thuanthong',
                     'Thurdchai', 'Thuwanan', 'Ti', 'Ti Nung Cha', 'Tikatath', 'Tiloka', 'Ting', 'Tinn', 'Tinnakiet',
                     'Tinnakit', 'Tinnakorn', 'Tinnapat', 'Tinnapob', 'Tinsulaananda', 'Tinsulanonda', 'Tiron',
                     'Tisorn',
                     'Tiwat', 'Ton', 'Tong', 'Tongkanlong', 'Tonnakorn', 'Tosanakorn', 'Totsakan', 'Toy', 'Trai',
                     'Traikun',
                     'Traipob', 'Traipoom', 'Traitod', 'Trat', 'Trin', 'Trinai', 'Trintawat', 'Tuksin', 'Tulathorn',
                     'Ubol',
                     'Udom', 'Unakan', 'Uthai', 'Vajiralongkorn', 'Vajiravudh', 'Varunvirya', 'Vessandan', 'Vichit',
                     'Vidura', 'Virote', 'Vit', 'Vitaya', 'Vitchu', 'Vithoon', 'Vuthisit', 'Warun', 'Wasan', 'Wasi',
                     'Watchara', 'Wattana', 'Wayupak', 'Weera', 'Winai', 'Wiset', 'Witsanunat', 'Wittaya', 'Witthawat',
                     'Witthaya', 'Wongsa', 'Worrawut', 'Xuwicha', 'Yai', 'Yhukon', 'Yindee', 'Yod', 'Yod Rak',
                     'Yod rak',
                     'Yongchaiyudh', 'Yongchaiyuth', 'Yongyuth', 'Yubamrung', 'Yuthakon')
                   THEN 'male'
               WHEN "firstname" IN
                    ('Abhasra', 'Achara', 'Adung', 'Ampawn', 'Amphorn', 'Amporn', 'Anchali', 'Anna', 'Anon', 'Apsara',
                     'Apsorn', 'Areva', 'Arinya', 'Arom', 'Atchara', 'Ausanat', 'Baenglum', 'Ban', 'Banjit',
                     'Bannarasee',
                     'Benjakalyani', 'Boon-Nam', 'Boon-mee', 'Boon-nam', 'Budsaba', 'Bundarik', 'Busaba', 'Busaya',
                     'But',
                     'Butri', 'Cantana', 'Catchada', 'Chaiama', 'Chalermwan', 'Chamnian', 'Chanachai', 'Chandra',
                     'Chanhira', 'Chantana', 'Chantara', 'Chanthara', 'Chantira', 'Chao-fa', 'Charanya', 'Chariya',
                     'Charoen', 'Charoenrasamee', 'Charunee', 'Chatmanee', 'Chatrsuda', 'Chatumas', 'Chaveevan',
                     'Chawiwan',
                     'Chintana', 'Chirawan', 'Choi', 'Chomechai', 'Chomesri', 'Chomkwan', 'Chompoo', 'Chompunut',
                     'Chomsiri', 'Chon', 'Chonnanee', 'Chonthicha', 'Chuachan', 'Chuasiri', 'Chulabhorn', 'Chulaborn',
                     'Chumbot', 'Churai', 'Cintna', 'Daeng', 'Damni', 'Dao', 'Darika', 'Darin', 'Dauenphen', 'Daw',
                     'Dhipyamongko', 'Dok mai', 'Dok', 'Dok-Rak', 'Dok-ban-yen', 'Dok-phi-sua', 'Dok-rak', 'Duan',
                     'Duang-Prapha', 'Duang-prapha', 'Duangnet', 'Duangrat', 'Durudee', 'Hansa', 'Hathai', 'Hiran',
                     'Hpr',
                     'Inthurat', 'Intira', 'Isaree', 'J�ew', 'Jaidee', 'Jintana', 'Jirattikarn', 'Jittramas',
                     'Jongchit',
                     'Jutharat', 'Kaeo', 'Kalaya', 'Kalya', 'Kamala', 'Kamchana', 'Kamonrat', 'Kanchana', 'Kanita',
                     'Kannika', 'Kanok', 'Kantima', 'Kanya', 'Karawek', 'Karn', 'Karnchana', 'Kasika', 'Keerati',
                     'Khae',
                     'Khakkhanang', 'Khantharot', 'Khem', 'Khiew Wan', 'Khouane', 'Khun Mae', 'Khun mae', 'Khun',
                     'Khunying', 'Kimnai', 'Kimuk', 'Klip', 'Kohsoom', 'Korrakoj', 'Kosum', 'Krijak', 'Krittiga',
                     'Kulap',
                     'Kultilda', 'Kusuman', 'Kwaanfah', 'Kwang', 'Kwanjai', 'Lalana', 'Lamai', 'Lamom', 'Lao', 'Lawan',
                     'Lek', 'Lukden', 'Ma-dee', 'Madee', 'Mae Noi', 'Mae', 'Mae-Duna', 'Mae-Khao', 'Mae-Pia',
                     'Mae-Ying-Thahan', 'Mae-duna', 'Mae-khao', 'Mae-noi', 'Mae-pia', 'Mae-ying-thahan', 'Mai',
                     'Maladee',
                     'Malee', 'Mali', 'Malisa', 'Malivalaya', 'Maliwan', 'Manee', 'Mani', 'Maniwan', 'Manya-Phathon',
                     'Manya-phathon', 'Maprang', 'Mathawee', 'Mayura', 'Mayuree', 'Mekhala', 'Mekhalaa', 'Mekhla',
                     'Monthani', 'Muan Nang', 'Mukda', 'Napatsorn', 'Napha', 'Narissa', 'Naruemon', 'Nataya', 'Natee',
                     'Nattaporn', 'Neeramphorn', 'Neung', 'Neungluthai', 'Ngam', 'Ngam-Chit', 'Ngor', 'Nidnoi', 'Nim',
                     'Nimnuan', 'Nin', 'Nisa', 'Nisarra', 'Nissa', 'Nittaya', 'Noi', 'Noklek', 'Nom', 'Nong Yao',
                     'Noom',
                     'Nopjira', 'Nuanjan', 'Nuntida', 'On Choi', 'On', 'Orapan', 'Orarat', 'Ornanong', 'Pada',
                     'Padungsri',
                     'Pakpao', 'Papao', 'Pasuta', 'Patcharee', 'Pathma', 'Patsaporn', 'Pen-Chan', 'Pensri', 'Pensria',
                     'Petchra', 'Phaibun', 'Phailin', 'Phairoh', 'Phajee', 'Phak-Phimonphan', 'Phak-phimonphan', 'Phan',
                     'Phannee', 'Phanthittra', 'Phara', 'Phatchara', 'Phathu', 'Phatra', 'Phawta', 'Phayao', 'Phi',
                     'Phim',
                     'Phitchaya', 'Phitsama�', 'Phitsamai', 'Phloi', 'Phueng', 'Piam', 'Piano', 'Pichitra', 'Pim',
                     'Pimchan', 'Pitsamai', 'Piyapat', 'Porntip', 'Pradtana', 'Praewphan', 'Prahong', 'Praitun',
                     'Pranee',
                     'Prang', 'Praphat', 'Preet', 'Preeya', 'Premwadee', 'Prevanutch', 'Prija', 'Prisana', 'Promporn',
                     'Pummie', 'Pundit', 'Punngarm', 'Putsaya', 'Rachanee', 'Rada', 'Raegan', 'Rajini', 'Rampha',
                     'Ramphoei', 'Rand', 'Ratana', 'Ratanaporn', 'Ratchanichon', 'Ratri', 'Rattana', 'Rawee', 'Rochana',
                     'Ruethai', 'Rung', 'Rutana', 'Saeng', 'Saengdao', 'Sairung', 'Samorn', 'Sanan Nam', 'Sangrawee',
                     'Sangwan', 'Sanoh', 'Sanouk', 'Saowakhon', 'Saowapa', 'Saowatharn', 'Sarai', 'Sarakit', 'Saruta',
                     'Sasi', 'Sasikarn', 'Savitree', 'Sawat', 'Sawatdi', 'Sawinee', 'Shalisa', 'Si Fah', 'Si Mok', 'Si',
                     'Siam', 'Simla', 'Sinee', 'Sinn', 'Sirikit', 'Sirindhorn', 'Sirirat', 'Solada', 'Som Chai',
                     'Som Kid',
                     'Som Wang', 'Som', 'Somawadi', 'Son-Klin', 'Son-klin', 'Songsuda', 'Sopa', 'Sri-Patana',
                     'Sri-patana',
                     'Srinak', 'Srisuriyothai', 'Sroy', 'Sua', 'Suchada', 'Suchin', 'Suchitra', 'Suda', 'Sugunya',
                     'Sujin',
                     'Sujitra', 'Sukanda', 'Sukhon', 'Sukonta', 'Suleeport', 'Sumalee', 'Sumana', 'Sumniang', 'Sunanda',
                     'Sunatda', 'Sunee', 'Sunetra', 'Sunisa', 'Sunstra', 'Sup', 'Supaporn', 'Supharang', 'Suree',
                     'Sureeporn', 'Suttida', 'Suwattanee', 'Taeng', 'Talap', 'Tamarine', 'Tasanee', 'Teerana',
                     'Thailah',
                     'Thaksincha', 'Thao-Ap', 'Thao-ap', 'Thara', 'Theetika', 'Thiang', 'Thikhamphorn', 'Thong Dam',
                     'Thong Khao', 'Thong Thaem', 'Thong Thao', 'Thong', 'Thongyip', 'Thunyarat', 'Tida', 'Tidarat',
                     'Tookta', 'Toptim', 'Totsaken', 'Touraine', 'Tppiwan', 'Tuani', 'Tui', 'Tuk', 'Tukata', 'Tulaya',
                     'Tum', 'Tunlaya', 'Tuptim', 'Ubol', 'Ubolratana', 'Udom', 'Um', 'Ung', 'Urairat', 'Uthai',
                     'Utumporn',
                     'Vanida', 'Vipada', 'Waan', 'Waen', 'Wan', 'Wani-Ratana-Kanya', 'Wansa', 'Waralee', 'Wasana',
                     'Wayo',
                     'Wila', 'Wilasinee', 'Wimon', 'Winai', 'Wipa', 'Wismita', 'Wonnapa', 'Xuwicha', 'Ya Chai', 'Yada',
                     'Yaowalak', 'Yaowaman', 'Yen', 'Yindee', 'Ying', 'Yodman', 'Yodmani', 'Yong-Yut', 'Yrita',
                     'Yu-Pha',
                     'Yu-Phin', 'Yupin')
                   THEN
                   'female'
               ELSE
                   "gender"
               END
);

UPDATE "MemberCustomer"
SET "gender" = (
    SELECT CASE
               WHEN "firstname" IN
                    ('Aat', 'Aawut', 'Adirake', 'Akkanee', 'Akkarat', 'Alak', 'Amnuay', 'Anada', 'Ananada', 'Ananda',
                     'Annan', 'Anon', 'Anuia', 'Anuman', 'Anurak', 'Anuthat', 'Apichart', 'Aran', 'Aroon', 'Arthit',
                     'Ashwin', 'Asnee', 'Athiti', 'Atid', 'Badinton', 'Baharn', 'Bahn', 'Bandasak', 'Banjong', 'Banlop',
                     'Banlue', 'Bannarasee', 'Bannarot', 'Bannasorn', 'Banthorn', 'Banwithit', 'Banyat', 'Banyong',
                     'Bapit',
                     'Barinai', 'Barinot', 'Baritharn', 'Baroma', 'Baveethran', 'Bawornnon', 'Bawornthath', 'Bhakdi',
                     'Bhichai', 'Bhumipol', 'Bin', 'Bodesta', 'Boon-Mee', 'Boon-Nam', 'Boon-mee', 'Boon-nam', 'Boonchu',
                     'Boonma', 'Boonpipob', 'Boontung', 'Brosong', 'Buangam', 'Budin', 'Bunbongkarn', 'Bunkit',
                     'Bunyakorn',
                     'Bunyapoo', 'Buppakorn', 'Burapol', 'Burimas', 'Burin', 'Burit', 'Burut', 'Cha', 'Chai',
                     'Chai Son',
                     'Chairat', 'Chaisai', 'Chaiya', 'Chaiyanuchit', 'Chaiyo', 'Chakan', 'Chakrabandhu', 'Chakri',
                     'Chalerm', 'Chalermchai', 'Chaloem', 'Chalong', 'Changsai', 'Channarong', 'Chanthara', 'Chao Fah',
                     'Chao-Tak', 'Chao-khun-sa', 'Chao-tak', 'Chaovalit', 'Chaowas', 'Charn Chai', 'Charnchai',
                     'Charoen',
                     'Charoensom', 'Charong', 'Chatalerm', 'Chatchalerm', 'Chatchawee', 'Chatchom', 'Chatichai',
                     'Chatri',
                     'Chaturon', 'Chavalit', 'Chayan', 'Chayond', 'Cheewaket', 'Chennoi', 'Chermsak', 'Chesda', 'Chet',
                     'Chetta', 'Chinawoot', 'Chiradet', 'Chomanan', 'Chompoo', 'Chon', 'Chongrak', 'Choochai',
                     'Choonhavan',
                     'Choonhavon', 'Chuachai', 'Chuan', 'Chuanchen', 'Chuchai', 'Chuia', 'Chula', 'Chulalongkorn',
                     'Chulamai', 'Churai', 'Chuthamani', 'Daeng', 'Damrong', 'Danai', 'Danit', 'Danunan', 'Danusorn',
                     'Daran', 'Daranpob', 'Darin', 'Decha', 'Deng', 'Denpoom', 'Dentharonee', 'Dhipyamongkol', 'Dilok',
                     'Diloktham', 'Disakorn', 'Disnadda', 'Disorn', 'Ditaka', 'Dithakar', 'Ditt', 'Dok', 'Dok rak',
                     'Dolrit', 'Dolsook', 'Dorn', 'Duchanee', 'Emjaroen', 'Erawan', 'Fah', 'Fufanwonich', 'Gee',
                     'Hainad',
                     'Hanuman', 'Hiran', 'Intradit', 'Ittiporn', 'Jaidee', 'Jao', 'Jarunsuk', 'Jatukamramthep',
                     'Jaturun',
                     'Jayavarman', 'Jessupha', 'Jettrin', 'Jirasak', 'Jutharat', 'Kaan', 'Kaandit', 'Kacha',
                     'Kamalakorn',
                     'Kamalanan', 'Kamalat', 'Kamik', 'Kamnan', 'Kamolpob', 'Kamolpoo', 'Kamut', 'Kan', 'Kananat',
                     'Kanaporn', 'Kanasanan', 'Kanda', 'Kandad', 'Kanin', 'Kanisorn', 'Kankawee', 'Kanok', 'Kanokpol',
                     'Kantapol', 'Kantapong', 'Kantayot', 'Kantharat', 'Kanthee', 'Kanthorn', 'Kantinan', 'Kantitat',
                     'Kantsak', 'Kantsom', 'Kanut', 'Kapp', 'Karan', 'Karanyapat', 'Karin', 'Karit', 'Karmatha', 'Karn',
                     'Karom', 'Kasan', 'Kasem', 'Kasemchai', 'Kasemsan', 'Kasidid', 'Kasin', 'Kasom', 'Kate',
                     'Kathawut',
                     'Kavi', 'Kawee', 'Kawin', 'Kawinpob', 'Keerati', 'Keetau', 'Khakanang', 'Khanti', 'Khattiya',
                     'Khem',
                     'Khemanan', 'Khematat', 'Khematin', 'Khemin', 'Khemkhaeng', 'Khun', 'Khunpol', 'Khunsoek', 'Kiet',
                     'Kiettinonnapat', 'Kiettisuk', 'Kimhan', 'Kirakorn', 'Kit', 'Kitsakan', 'Kitsakorn', 'Kitt',
                     'Kitti',
                     'Kittibun', 'Kittichai', 'Kittichat', 'Kittikawin', 'Kittikchorn', 'Kittikorn', 'Kittinai',
                     'Kittinan',
                     'Kittipob', 'Kittipon', 'Kittipoom', 'Kittiporn', 'Kittipot', 'Kittisak', 'Kittitat', 'Kittithorn',
                     'Kittiwin', 'Kla', 'Kla Han', 'Klaew Kla', 'Klahan', 'Kob', 'Kob Chai', 'Kob Khun', 'Kob Sinn',
                     'Kob Sook', 'Kolatee', 'Komalat', 'Komn', 'Kongbej', 'Kongkidakorn', 'Kongpob', 'Kongsampong',
                     'Konthee', 'Konthorn', 'Koradol', 'Korakod', 'Koran', 'Korapoo', 'Korasut', 'Koratak', 'Korn',
                     'Kornballop', 'Kot', 'Kovit', 'Krairawee', 'Kraisee', 'Kraisingha', 'Kraiwin', 'Krarayoon',
                     'Kriang Krai', 'Kriang Sak', 'Kriangsak', 'Kriengsak', 'Kris', 'Krisik', 'Krit', 'Krita',
                     'Kritsada',
                     'Krittameth', 'Krittanoo', 'Krittapat', 'Krittapot', 'Krittayot', 'Krittin', 'Krittinai',
                     'Krittithee',
                     'Krom-Luang', 'Krom-luang', 'Kukrit', 'Kulit', 'Kulpat', 'Kulthorn', 'Kunach', 'Kunanan', 'Kunn',
                     'Kunnthorn', 'Kusa', 'Kusum', 'Kutsa', 'Kwanchai', 'Kwanjai', 'Lamom', 'Lamon', 'Lap', 'Leekpai',
                     'Leekpie', 'Lek', 'Loesan', 'Luk', 'Maha', 'Mahidol', 'Malian', 'Maliwan', 'Manee', 'Manitho',
                     'Mee',
                     'Mee Noi', 'Mengrai', 'Metananda', 'Mok', 'Mokkhavesa', 'Molthisok', 'Mongkut', 'Monyakul', 'Muoi',
                     'Nadee', 'Nai-Thim', 'Nai-thim', 'Nak', 'Nakaret', 'Nakarin', 'Nang-Klao', 'Nang-klao',
                     'Nanthapob',
                     'Nanthayot', 'Nanthit', 'Nantin', 'Nantipat', 'Nantiworn', 'Napan', 'Napat', 'Napatthorn', 'Napon',
                     'Narai', 'Naresuan', 'Naris', 'Narisa', 'Narong', 'Narongrit', 'Narongwit', 'Naruerong',
                     'Naruesorn',
                     'Nat', 'Natee', 'Nathawat', 'Nattadanai', 'Nattakamol', 'Nattakan', 'Nattanai', 'Nattanan',
                     'Nattanon',
                     'Nattapat', 'Nattapon', 'Nattaron', 'Nattasit', 'Nattasom', 'Nattasut', 'Nattawat', 'Nattaworn',
                     'Nattayot', 'Natthapong', 'Natthawut', 'Nawanthorn', 'Nawat', 'Nawatkorn', 'Nawin', 'Nekk', 'Net',
                     'Netithorn', 'Netiwit', 'Ngam', 'Ngoen', 'Nibun', 'Nikom', 'Nikon', 'Nimman', 'Nimmit', 'Nintau',
                     'Nipaat', 'Nipat', 'Niphon', 'Nipit', 'Nipitpon', 'Nipon', 'Nipun', 'Niran', 'Nirawit', 'Nirin',
                     'Nirund', 'Nissorn', 'Nit', 'Nithan', 'Nithikorn', 'Nithit', 'Nithoon', 'Nitithorn', 'Nitthan',
                     'Nitthon', 'Niwat', 'Niwit', 'Niyom', 'Nodthakorn', 'Noi', 'Non', 'Nongchai', 'Nongkhai',
                     'Nonpawit',
                     'Nontapan', 'Nontawat', 'Nontiyut', 'Nopjira', 'Noppadon', 'Noppadorn', 'Noppakorn', 'Noppasin',
                     'Noppathee', 'Noppawin', 'Norachai', 'Norrapan', 'Norrapon', 'Norrathee', 'Norrawee', 'Norraworn',
                     'Nuananong', 'Nuengnimman', 'Nugoon', 'Nui', 'Nung', 'Nuta-Laya', 'Nuta-laya', 'Obb', 'Olan',
                     'Osathee', 'Othong', 'Paan', 'Paanthath', 'Pairat', 'Pairote', 'Paitoon', 'Pakhdi', 'Palat',
                     'Pamut',
                     'Pan', 'Panas', 'Panat', 'Panithi', 'Pann', 'Pannathath', 'Pannathorn', 'Pannawat', 'Panthorn',
                     'Panyarachun', 'Papangkorn', 'Paparn', 'Papawin', 'Papob', 'Papon', 'Paponsan', 'Paponthanai',
                     'Paponthee', 'Paradorn', 'Parama', 'Paraman', 'Paramat', 'Paramendr', 'Paranat', 'Parat', 'Parin',
                     'Parit', 'Parnchand', 'Paron', 'Parun', 'Pasan', 'Pasat', 'Pasut', 'Pathanin', 'Pathapee',
                     'Pathit',
                     'Patipon', 'Patt', 'Pattama', 'Pawaret', 'Pawarit', 'Pawaritsorn', 'Pawarut', 'Pawat', 'Paween',
                     'Pawin', 'Pawit', 'Pawornruj', 'Payut', 'Pet', 'Petch', 'Petchara', 'Petchra', 'Phaibun',
                     'Phaithoon',
                     'Phanumas', 'Phara', 'Phassakorn', 'Phatra', 'Phatson', 'Phet', 'Phichai', 'Phichit', 'Phinihan',
                     'Phisan', 'Phongsak', 'Phraisong', 'Phrom-Borirak', 'Phrom-borirak', 'Phueng', 'Phuri', 'Phya',
                     'Pichai', 'Pichit', 'Pidok', 'Pira', 'Piya', 'Piyabutr', 'Piyapat', 'Piyapon', 'Piyatat',
                     'Piyawat',
                     'Ponggool', 'Pongkun', 'Pongpanet', 'Pongpob', 'Pongrit', 'Pongsom', 'Pongtham', 'Pra', 'Pracha',
                     'Prachuab', 'Prakit', 'Prakorb', 'Pralop', 'Praman', 'Pramanat', 'Pramod', 'Pramoj', 'Pramon',
                     'Pran',
                     'Pranai', 'Pranon', 'Pranop', 'Prapaan', 'Prapan', 'Prapawit', 'Prasong', 'Prasopchai', 'Pravat',
                     'Praves', 'Prawanwit', 'Prawee', 'Praween', 'Praya', 'Prayut', 'Preet', 'Prem', 'Pricha', 'Prid',
                     'Prisna', 'Pritsadee', 'Pritsanee', 'Proi', 'Pu', 'Pu Yai Bahn', 'Puenthai', 'Puran', 'Puttipat',
                     'Rachotai', 'Raegan', 'Rajanon', 'Rak', 'Rama', 'Ramkamhaeng', 'Rand', 'Rangsan', 'Rangsiman',
                     'Ratanankorn', 'Ratri', 'Ratsami', 'Rawee', 'Ritthirong', 'Rom Ran', 'Ronnapee', 'Ruang Rit',
                     'Ruang Sak', 'Runrot', 'Sajja', 'Sakchai', 'Sakda', 'Sampan', 'Samyan', 'San''ya', 'Sanan',
                     'Sanouk',
                     'Santichai', 'Sanun', 'Sap', 'Saranyu', 'Sarathoon', 'Sarawong', 'Sarawut', 'Sarit', 'Sarut',
                     'Sataheep', 'Satayu', 'Satra', 'Satrud', 'Savit', 'Sawai', 'Sawat', 'Seni', 'Seri', 'Si', 'Siam',
                     'Siddhi', 'Sin', 'Singnum', 'Sinn', 'Snoh', 'Som', 'Som Phon', 'Som Phong', 'Sombat', 'Somchai',
                     'Somchair', 'Somchith', 'Somdej', 'Somdet-Ong-Yai', 'Somdet-ong-yai', 'Somdetch', 'Sompron',
                     'Somsak',
                     'Somwang', 'Son', 'Son Chai', 'Sonchai', 'Songgram', 'Songpob', 'Songpole', 'Songwut', 'Soo',
                     'Sook',
                     'Sophuk', 'Srimuang', 'Staporn', 'Su', 'Su Suk', 'Suchin', 'Sud', 'Sud Saming', 'Suda', 'Sudarak',
                     'Suk', 'Sulak', 'Sum', 'Sumatra', 'Sunan', 'Sundaravej', 'Suntarankul', 'Sunti', 'Sunya', 'Sup',
                     'Suphatra', 'Suphayok', 'Supoj', 'Supp', 'Supsampantuwongse', 'Sura', 'Surasak', 'Surat', 'Surin',
                     'Suriwongse', 'Suriyawong', 'Sutep', 'Suthep', 'Suttipong', 'Taan', 'Tadpol', 'Tadpong',
                     'Tadsuang',
                     'Tadthep', 'Tadthon', 'Taeng', 'Tai', 'Tak', 'Tak-Sin', 'Tak-sin', 'Takdanai', 'Tam', 'Tamnurath',
                     'Tanakrit', 'Tangpanitharn', 'Tanit', 'Tanupat', 'Tanusorn', 'Tanutam', 'Tapp', 'Tappasan',
                     'Taran',
                     'Tarrin', 'Tassapon', 'Tau', 'Taweepak', 'Taweerat', 'Tayakorn', 'Tayut', 'Teepakorn', 'Teepth',
                     'Teera', 'Tep', 'Teptath', 'Thahan', 'Thaklaew', 'Thaksin', 'Tham-Boon', 'Tham-boon', 'Thammanit',
                     'Thammaraja', 'Thammasorn', 'Thampapon', 'Thampon', 'Thamwat', 'Thanaboon', 'Thanadol', 'Thanadun',
                     'Thanalop', 'Thanandorn', 'Thananop', 'Thanapon', 'Thanapoom', 'Thanarat', 'Thanat', 'Thanatat',
                     'Thanawan', 'Thanawat', 'Thanawin', 'Thanayut', 'Thanee', 'Thanetpol', 'Thanid', 'Thanik',
                     'Thanin',
                     'Thanit', 'Thanom', 'Thanut', 'Thanwa', 'Thanya', 'Thapthim', 'Tharathep', 'Tharathorn', 'Tharit',
                     'Tharn', 'Thath', 'Thawan', 'Thawanya', 'Thawi', 'Thawin', 'Thawit', 'Thayot', 'Theema', 'Theepob',
                     'Theera', 'Theeradon', 'Theerameth', 'Theeranai', 'Theeranop', 'Theerapat', 'Theerapatpong',
                     'Theerat',
                     'Theeratham', 'Theeratorn', 'Theerit', 'Theerut', 'Theesud', 'Theethath', 'Thinnakorn', 'Thipok',
                     'Thira', 'Thirakun', 'Thiramon', 'Thiranai', 'Thiraput', 'Thirdpong', 'Thith', 'Thiti', 'Thitipan',
                     'Thitisan', 'Thitisorn', 'Thitiwat', 'Thitiwut', 'Thong Daeng', 'Thong Di', 'Thong Kon',
                     'Thong Thaeng', 'Thongchai', 'Thongkon', 'Thoranan', 'Thorm', 'Thorn', 'Thornthep', 'Thuanthong',
                     'Thurdchai', 'Thuwanan', 'Ti', 'Ti Nung Cha', 'Tikatath', 'Tiloka', 'Ting', 'Tinn', 'Tinnakiet',
                     'Tinnakit', 'Tinnakorn', 'Tinnapat', 'Tinnapob', 'Tinsulaananda', 'Tinsulanonda', 'Tiron',
                     'Tisorn',
                     'Tiwat', 'Ton', 'Tong', 'Tongkanlong', 'Tonnakorn', 'Tosanakorn', 'Totsakan', 'Toy', 'Trai',
                     'Traikun',
                     'Traipob', 'Traipoom', 'Traitod', 'Trat', 'Trin', 'Trinai', 'Trintawat', 'Tuksin', 'Tulathorn',
                     'Ubol',
                     'Udom', 'Unakan', 'Uthai', 'Vajiralongkorn', 'Vajiravudh', 'Varunvirya', 'Vessandan', 'Vichit',
                     'Vidura', 'Virote', 'Vit', 'Vitaya', 'Vitchu', 'Vithoon', 'Vuthisit', 'Warun', 'Wasan', 'Wasi',
                     'Watchara', 'Wattana', 'Wayupak', 'Weera', 'Winai', 'Wiset', 'Witsanunat', 'Wittaya', 'Witthawat',
                     'Witthaya', 'Wongsa', 'Worrawut', 'Xuwicha', 'Yai', 'Yhukon', 'Yindee', 'Yod', 'Yod Rak',
                     'Yod rak',
                     'Yongchaiyudh', 'Yongchaiyuth', 'Yongyuth', 'Yubamrung', 'Yuthakon')
                   THEN 'male'
               WHEN "firstname" IN
                    ('Abhasra', 'Achara', 'Adung', 'Ampawn', 'Amphorn', 'Amporn', 'Anchali', 'Anna', 'Anon', 'Apsara',
                     'Apsorn', 'Areva', 'Arinya', 'Arom', 'Atchara', 'Ausanat', 'Baenglum', 'Ban', 'Banjit',
                     'Bannarasee',
                     'Benjakalyani', 'Boon-Nam', 'Boon-mee', 'Boon-nam', 'Budsaba', 'Bundarik', 'Busaba', 'Busaya',
                     'But',
                     'Butri', 'Cantana', 'Catchada', 'Chaiama', 'Chalermwan', 'Chamnian', 'Chanachai', 'Chandra',
                     'Chanhira', 'Chantana', 'Chantara', 'Chanthara', 'Chantira', 'Chao-fa', 'Charanya', 'Chariya',
                     'Charoen', 'Charoenrasamee', 'Charunee', 'Chatmanee', 'Chatrsuda', 'Chatumas', 'Chaveevan',
                     'Chawiwan',
                     'Chintana', 'Chirawan', 'Choi', 'Chomechai', 'Chomesri', 'Chomkwan', 'Chompoo', 'Chompunut',
                     'Chomsiri', 'Chon', 'Chonnanee', 'Chonthicha', 'Chuachan', 'Chuasiri', 'Chulabhorn', 'Chulaborn',
                     'Chumbot', 'Churai', 'Cintna', 'Daeng', 'Damni', 'Dao', 'Darika', 'Darin', 'Dauenphen', 'Daw',
                     'Dhipyamongko', 'Dok mai', 'Dok', 'Dok-Rak', 'Dok-ban-yen', 'Dok-phi-sua', 'Dok-rak', 'Duan',
                     'Duang-Prapha', 'Duang-prapha', 'Duangnet', 'Duangrat', 'Durudee', 'Hansa', 'Hathai', 'Hiran',
                     'Hpr',
                     'Inthurat', 'Intira', 'Isaree', 'J�ew', 'Jaidee', 'Jintana', 'Jirattikarn', 'Jittramas',
                     'Jongchit',
                     'Jutharat', 'Kaeo', 'Kalaya', 'Kalya', 'Kamala', 'Kamchana', 'Kamonrat', 'Kanchana', 'Kanita',
                     'Kannika', 'Kanok', 'Kantima', 'Kanya', 'Karawek', 'Karn', 'Karnchana', 'Kasika', 'Keerati',
                     'Khae',
                     'Khakkhanang', 'Khantharot', 'Khem', 'Khiew Wan', 'Khouane', 'Khun Mae', 'Khun mae', 'Khun',
                     'Khunying', 'Kimnai', 'Kimuk', 'Klip', 'Kohsoom', 'Korrakoj', 'Kosum', 'Krijak', 'Krittiga',
                     'Kulap',
                     'Kultilda', 'Kusuman', 'Kwaanfah', 'Kwang', 'Kwanjai', 'Lalana', 'Lamai', 'Lamom', 'Lao', 'Lawan',
                     'Lek', 'Lukden', 'Ma-dee', 'Madee', 'Mae Noi', 'Mae', 'Mae-Duna', 'Mae-Khao', 'Mae-Pia',
                     'Mae-Ying-Thahan', 'Mae-duna', 'Mae-khao', 'Mae-noi', 'Mae-pia', 'Mae-ying-thahan', 'Mai',
                     'Maladee',
                     'Malee', 'Mali', 'Malisa', 'Malivalaya', 'Maliwan', 'Manee', 'Mani', 'Maniwan', 'Manya-Phathon',
                     'Manya-phathon', 'Maprang', 'Mathawee', 'Mayura', 'Mayuree', 'Mekhala', 'Mekhalaa', 'Mekhla',
                     'Monthani', 'Muan Nang', 'Mukda', 'Napatsorn', 'Napha', 'Narissa', 'Naruemon', 'Nataya', 'Natee',
                     'Nattaporn', 'Neeramphorn', 'Neung', 'Neungluthai', 'Ngam', 'Ngam-Chit', 'Ngor', 'Nidnoi', 'Nim',
                     'Nimnuan', 'Nin', 'Nisa', 'Nisarra', 'Nissa', 'Nittaya', 'Noi', 'Noklek', 'Nom', 'Nong Yao',
                     'Noom',
                     'Nopjira', 'Nuanjan', 'Nuntida', 'On Choi', 'On', 'Orapan', 'Orarat', 'Ornanong', 'Pada',
                     'Padungsri',
                     'Pakpao', 'Papao', 'Pasuta', 'Patcharee', 'Pathma', 'Patsaporn', 'Pen-Chan', 'Pensri', 'Pensria',
                     'Petchra', 'Phaibun', 'Phailin', 'Phairoh', 'Phajee', 'Phak-Phimonphan', 'Phak-phimonphan', 'Phan',
                     'Phannee', 'Phanthittra', 'Phara', 'Phatchara', 'Phathu', 'Phatra', 'Phawta', 'Phayao', 'Phi',
                     'Phim',
                     'Phitchaya', 'Phitsama�', 'Phitsamai', 'Phloi', 'Phueng', 'Piam', 'Piano', 'Pichitra', 'Pim',
                     'Pimchan', 'Pitsamai', 'Piyapat', 'Porntip', 'Pradtana', 'Praewphan', 'Prahong', 'Praitun',
                     'Pranee',
                     'Prang', 'Praphat', 'Preet', 'Preeya', 'Premwadee', 'Prevanutch', 'Prija', 'Prisana', 'Promporn',
                     'Pummie', 'Pundit', 'Punngarm', 'Putsaya', 'Rachanee', 'Rada', 'Raegan', 'Rajini', 'Rampha',
                     'Ramphoei', 'Rand', 'Ratana', 'Ratanaporn', 'Ratchanichon', 'Ratri', 'Rattana', 'Rawee', 'Rochana',
                     'Ruethai', 'Rung', 'Rutana', 'Saeng', 'Saengdao', 'Sairung', 'Samorn', 'Sanan Nam', 'Sangrawee',
                     'Sangwan', 'Sanoh', 'Sanouk', 'Saowakhon', 'Saowapa', 'Saowatharn', 'Sarai', 'Sarakit', 'Saruta',
                     'Sasi', 'Sasikarn', 'Savitree', 'Sawat', 'Sawatdi', 'Sawinee', 'Shalisa', 'Si Fah', 'Si Mok', 'Si',
                     'Siam', 'Simla', 'Sinee', 'Sinn', 'Sirikit', 'Sirindhorn', 'Sirirat', 'Solada', 'Som Chai',
                     'Som Kid',
                     'Som Wang', 'Som', 'Somawadi', 'Son-Klin', 'Son-klin', 'Songsuda', 'Sopa', 'Sri-Patana',
                     'Sri-patana',
                     'Srinak', 'Srisuriyothai', 'Sroy', 'Sua', 'Suchada', 'Suchin', 'Suchitra', 'Suda', 'Sugunya',
                     'Sujin',
                     'Sujitra', 'Sukanda', 'Sukhon', 'Sukonta', 'Suleeport', 'Sumalee', 'Sumana', 'Sumniang', 'Sunanda',
                     'Sunatda', 'Sunee', 'Sunetra', 'Sunisa', 'Sunstra', 'Sup', 'Supaporn', 'Supharang', 'Suree',
                     'Sureeporn', 'Suttida', 'Suwattanee', 'Taeng', 'Talap', 'Tamarine', 'Tasanee', 'Teerana',
                     'Thailah',
                     'Thaksincha', 'Thao-Ap', 'Thao-ap', 'Thara', 'Theetika', 'Thiang', 'Thikhamphorn', 'Thong Dam',
                     'Thong Khao', 'Thong Thaem', 'Thong Thao', 'Thong', 'Thongyip', 'Thunyarat', 'Tida', 'Tidarat',
                     'Tookta', 'Toptim', 'Totsaken', 'Touraine', 'Tppiwan', 'Tuani', 'Tui', 'Tuk', 'Tukata', 'Tulaya',
                     'Tum', 'Tunlaya', 'Tuptim', 'Ubol', 'Ubolratana', 'Udom', 'Um', 'Ung', 'Urairat', 'Uthai',
                     'Utumporn',
                     'Vanida', 'Vipada', 'Waan', 'Waen', 'Wan', 'Wani-Ratana-Kanya', 'Wansa', 'Waralee', 'Wasana',
                     'Wayo',
                     'Wila', 'Wilasinee', 'Wimon', 'Winai', 'Wipa', 'Wismita', 'Wonnapa', 'Xuwicha', 'Ya Chai', 'Yada',
                     'Yaowalak', 'Yaowaman', 'Yen', 'Yindee', 'Ying', 'Yodman', 'Yodmani', 'Yong-Yut', 'Yrita',
                     'Yu-Pha',
                     'Yu-Phin', 'Yupin')
                   THEN
                   'female'
               ELSE
                   'male'
               END
)::GENDER
WHERE 1 = 1;

-- Randomize Employee's joinDate by referencing birthdate
UPDATE "Employee"
SET "joinDate" = (
    SELECT "birthdate" +
           ("random_between"(15, 17) || ' year ' || "random_between"(1, 12) || ' month ' || "random_between"(1, 30) ||
            ' day ' || "random_between"(0, 24) || ' hour ' || "random_between"(0, 60) || ' min ' ||
            "random_between"(0, 60) ||
            ' seconds')::INTERVAL
)
WHERE "joinDate" = '2020-09-15';


-- Randomly populate Branch to each Employee
UPDATE "Employee" "E"
SET "branchId" = (
    SELECT CASE
               WHEN exists(SELECT "branchId" FROM "Branch" WHERE "provinceId" = "E"."provinceId")
                   THEN
                   (
                       SELECT "branchId"
                       FROM "Branch" "X"
                       WHERE "X"."provinceId" = "E"."provinceId"
                       ORDER BY (SELECT (
                                            SELECT random()
                                            WHERE "g" = "g"
                                              AND "X"."branchId" = "X"."branchId"
                                        )
                                 FROM generate_series(1, 10) "g"
                                 LIMIT 1)
                       LIMIT 1
                   )
               ELSE
                   (
                       SELECT "branchId"
                       FROM "Branch" "X"
                       WHERE "E"."employeeId" = "E"."employeeId"
                       ORDER BY (SELECT (
                                            SELECT random()
                                            WHERE "g" = "g"
                                              AND "X"."provinceId" = "X"."provinceId"
                                        )
                                 FROM generate_series(1, 10) "g"
                                 LIMIT 1)
                       LIMIT 1
                   )
               END
);

--Random time range between 15 - 100 minutes
UPDATE "InventoryInboundOrder"
SET "deliveryIn" = (
    SELECT ("random_between"(25, 235) || ' min')::INTERVAL
    WHERE "inboundOrderId" = "inboundOrderId"
)
WHERE 1 = 1;


-- List employees who has no positions at all!
SELECT "E"."employeeId", "BM"."employeeId", "C"."employeeId", "C2"."employeeId", "DM"."employeeId"
FROM "Employee" "E"
         LEFT JOIN "BranchManager" "BM" ON "E"."employeeId" = "BM"."employeeId"
         LEFT JOIN "Cashier" "C" ON "E"."employeeId" = "C"."employeeId"
         LEFT JOIN "Chef" "C2" ON "E"."employeeId" = "C2"."employeeId"
         LEFT JOIN "DeliveryMan" "DM" ON "E"."employeeId" = "DM"."employeeId"
WHERE "C"."employeeId" IS NULL
  AND "BM"."employeeId" IS NULL
  AND "C2"."employeeId" IS NULL
  AND "DM"."employeeId" IS NULL;

DO
$$
    DECLARE
        "employee"         "Employee";
        "isPartTime"       BOOL;
        "timeOffset"       CHAR(2);
        "branchOps"        RECORD;
        "insertedWorkTime" RECORD;
        "timeOpen"         TIME;
        "timeClose"        TIME;
    BEGIN

        FOR "employee" IN (SELECT * FROM "Employee")
            LOOP
                RAISE NOTICE 'Counter %', "employee";

                FOR "branchOps" IN (SELECT "dayOfWeek", "timeOpening", "timeClosing"
                                    FROM "Branch"
                                             JOIN "BranchOpenTime" "BOT" ON "Branch"."branchId" = "BOT"."branchId"
                                    WHERE "Branch"."branchId" = "employee"."branchId")
                    LOOP

                        SELECT (("employee"."age" < 20) AND ("branchOps"."dayOfWeek" NOT IN ('sunday', 'saturday')))
                        INTO "isPartTime";
                        RAISE NOTICE '%', "branchOps";

                        SELECT (ARRAY ['10', '15', '30'])[floor(random() * 3 + 1)] INTO "timeOffset";

                        "timeOpen" := "branchOps"."timeOpening";
                        "timeClose" := "branchOps"."timeClosing";
                        IF "isPartTime" = TRUE THEN
                            "timeOpen" := '16:00'::TIME;
                            "timeClose" := "timeClose";
                        END IF;


                        INSERT INTO "WorkTime"
                        VALUES (DEFAULT, "branchOps"."dayOfWeek", "timeOpen" - ("timeOffset" || ' minute')::INTERVAL,
                                "timeClose" + ("timeOffset" || ' minute')::INTERVAL,
                                "isPartTime", "employee"."employeeId")
                        RETURNING * INTO "insertedWorkTime";

                        RAISE NOTICE 'Work Time => %', "branchOps";
                    END LOOP;
            END LOOP;
    END
$$;


-- Populate MenuAvailability for each menu
DO
$$
    DECLARE
        "itMenuRef"              "MenuRef";
        "hasSpecialAvailability" BOOL;
        "afternoonOnly"          BOOL;
        "dayOfWeeks"             "day_of_week"[] := ARRAY ['monday', 'tuesday', 'wednesday', 'thursday', 'friday', 'saturday', 'sunday'];
        "itDayOfWeek"            "day_of_week";
        "itTimeStart"            TIME;
        "itTimeEnd"              TIME;
        "i"                      INT;
    BEGIN

        FOR "itMenuRef" IN (SELECT * FROM "MenuRef")
            LOOP
                "hasSpecialAvailability" := random() < 0.2;
                "afternoonOnly" := random() < 0.1;

                FOR "i" IN array_lower("dayOfWeeks", 1)..array_upper("dayOfWeeks", 1)
                    LOOP
                        "itDayOfWeek" := "dayOfWeeks"["i"];
                        IF "hasSpecialAvailability" AND "itDayOfWeek" = ANY
                                                        (ARRAY ['monday'::"day_of_week", 'tuesday'::"day_of_week", 'wednesday'::"day_of_week"]) THEN
                            CONTINUE;
                        END IF;

                        IF "afternoonOnly" THEN
                            SELECT MIN("timeOpening") INTO "itTimeStart" FROM "BranchOpenTime";
                            SELECT MIN("timeClosing") INTO "itTimeEnd" FROM "BranchOpenTime";
                        ELSE
                            SELECT '12:00'::TIME INTO "itTimeStart" FROM "BranchOpenTime";
                            SELECT '15:00'::TIME INTO "itTimeEnd" FROM "BranchOpenTime";
                        END IF;

                        INSERT INTO "MenuAvailability"
                        VALUES ((SELECT coalesce(MAX("menuAvailabilityId"), 0) + 1 FROM "MenuAvailability"),
                                "itDayOfWeek", "itTimeStart", "itTimeEnd", "itMenuRef"."menuRefId");
                    END LOOP;
            END LOOP;

    END;
$$;