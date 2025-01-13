# TODO: Find a way to add a -NoOutput parameter to the main script in service of only defining the functions
# TODO: Try adding a -Measure switch to show each function's execution time
#   i.e. Terminal (0.35ms): Windows Terminal
#   $cmdtime = Measure-Command -Expression {$info = & "info_$item"}
#   $info['title'] += " ($($cmdtime.TotalMilliseconds)ms):"

# get CIM session for use with winfetch functions
$cimSession = New-CimSession

# <<==================================================< winfetch test functions
# <<===================<< Resolution Original (.NET)
function info_resolution_net {
    Add-Type -AssemblyName System.Windows.Forms
    $displays = foreach ($monitor in [System.Windows.Forms.Screen]::AllScreens) {
        "$($monitor.Bounds.Size.Width)x$($monitor.Bounds.Size.Height)"
    }

    return @{
        title   = 'Resolution'
        content = $displays -join ', '
    }
}
# <<===================<< Resolution (CIM)
function info_resolution_wmi {
    # DPI Settings
    # https://learn.microsoft.com/en-us/windows-hardware/manufacture/desktop/dpi-related-apis-and-registry-settings?view=windows-11
    $CIMResolution = gcim Win32_VideoController -CimSession $cimSession | Select-Object CurrentHorizontalResolution, CurrentVerticalResolution, CurrentRefreshRate
    return @{
        title   = 'Resolution'
        content = "$($CIMResolution.CurrentHorizontalResolution)x$($CIMResolution.CurrentVerticalResolution) @ $($CIMResolution.CurrentRefreshRate)Hz"
    }
}
# <<===================<< Locale Original (Registry/Hashtable)
function info_locale_reg {
    # Hashtables for language and region codes
    $localeLookup = @{
        '10'        = 'American Samoa';            '100'       = 'Guinea';                    '10026358'  = 'Americas';
        '10028789'  = 'Åland Islands';             '10039880'  = 'Caribbean';                 '10039882'  = 'Northern Europe';
        '10039883'  = 'Southern Africa';           '101'       = 'Guyana';                    '10210824'  = 'Western Europe';
        '10210825'  = 'Australia and New Zealand'; '103'       = 'Haiti';                     '104'       = 'Hong Kong SAR';
        '10541'     = 'Europe';                    '106'       = 'Honduras';                  '108'       = 'Croatia';
        '109'       = 'Hungary';                   '11'        = 'Argentina';                 '110'       = 'Iceland';
        '111'       = 'Indonesia';                 '113'       = 'India';                     '114'       = 'British Indian Ocean Territory';
        '116'       = 'Iran';                      '117'       = 'Israel';                    '118'       = 'Italy';
        '119'       = "Côte d'Ivoire";             '12'        = 'Australia';                 '121'       = 'Iraq';
        '122'       = 'Japan';                     '124'       = 'Jamaica';                   '125'       = 'Jan Mayen';
        '126'       = 'Jordan';                    '127'       = 'Johnston Atoll';            '129'       = 'Kenya';
        '130'       = 'Kyrgyzstan';                '131'       = 'North Korea';               '133'       = 'Kiribati';
        '134'       = 'Korea';                     '136'       = 'Kuwait';                    '137'       = 'Kazakhstan';
        '138'       = 'Laos';                      '139'       = 'Lebanon';                   '14'        = 'Austria';
        '140'       = 'Latvia';                    '141'       = 'Lithuania';                 '142'       = 'Liberia';
        '143'       = 'Slovakia';                  '145'       = 'Liechtenstein';             '146'       = 'Lesotho';
        '147'       = 'Luxembourg';                '148'       = 'Libya';                     '149'       = 'Madagascar';
        '151'       = 'Macao SAR';                 '15126'     = 'Isle of Man';               '152'       = 'Moldova';
        '154'       = 'Mongolia';                  '156'       = 'Malawi';                    '157'       = 'Mali';
        '158'       = 'Monaco';                    '159'       = 'Morocco';                   '160'       = 'Mauritius';
        '161832015' = 'Saint Barthélemy';          '161832256' = 'U.S. Minor Outlying Islands'; '161832257' = 'Latin America and the Caribbean';
        '161832258' = 'Bonaire, Sint Eustatius and Saba'; '162' = 'Mauritania';               '163'       = 'Malta';
        '164'       = 'Oman';                     '165'       = 'Maldives';                 '166'       = 'Mexico';
        '167'       = 'Malaysia';                 '168'       = 'Mozambique';               '17'        = 'Bahrain';
        '173'       = 'Niger';                    '174'       = 'Vanuatu';                  '175'       = 'Nigeria';
        '176'       = 'Netherlands';              '177'       = 'Norway';                   '178'       = 'Nepal';
        '18'        = 'Barbados';                 '180'       = 'Nauru';                    '181'       = 'Suriname';
        '182'       = 'Nicaragua';                '183'       = 'New Zealand';              '184'       = 'Palestinian Authority';
        '185'       = 'Paraguay';                 '187'       = 'Peru';                     '19'        = 'Botswana';
        '190'       = 'Pakistan';                 '191'       = 'Poland';                   '192'       = 'Panama';
        '193'       = 'Portugal';                 '194'       = 'Papua New Guinea';         '195'       = 'Palau';
        '196'       = 'Guinea-Bissau';            '19618'     = 'North Macedonia';          '197'       = 'Qatar';
        '198'       = 'Réunion';                  '199'       = 'Marshall Islands';         '2'         = 'Antigua and Barbuda';
        '20'        = 'Bermuda';                  '200'       = 'Romania';                  '201'       = 'Philippines';
        '202'       = 'Puerto Rico';              '203'       = 'Russia';                   '204'       = 'Rwanda';
        '205'       = 'Saudi Arabia';             '206'       = 'Saint Pierre and Miquelon'; '207'      = 'Saint Kitts and Nevis';
        '208'       = 'Seychelles';               '209'       = 'South Africa';             '20900'     = 'Melanesia';
        '21'        = 'Belgium';                  '210'       = 'Senegal';                  '212'       = 'Slovenia';
        '21206'     = 'Micronesia';               '21242'     = 'Midway Islands';           '2129'      = 'Asia';
        '213'       = 'Sierra Leone';             '214'       = 'San Marino';               '215'       = 'Singapore';
        '216'       = 'Somalia';                  '217'       = 'Spain';                    '218'       = 'Saint Lucia';
        '219'       = 'Sudan';                    '22'        = 'Bahamas';                  '220'       = 'Svalbard';
        '221'       = 'Sweden';                   '222'       = 'Syria';                    '223'       = 'Switzerland';
        '224'       = 'United Arab Emirates';     '225'       = 'Trinidad and Tobago';      '227'       = 'Thailand';
        '228'       = 'Tajikistan';               '23'        = 'Bangladesh';               '231'       = 'Tonga';
        '232'       = 'Togo';                     '233'       = 'São Tomé and Príncipe';    '234'       = 'Tunisia';
        '235'       = 'Turkey';                   '23581'     = 'Northern America';         '236'       = 'Tuvalu';
        '237'       = 'Taiwan';                   '238'       = 'Turkmenistan';             '239'       = 'Tanzania';
        '24'        = 'Belize';                   '240'       = 'Uganda';                   '241'       = 'Ukraine';
        '242'       = 'United Kingdom';           '244'       = 'United States';            '245'       = 'Burkina Faso';
        '246'       = 'Uruguay';                  '247'       = 'Uzbekistan';               '248'       = 'Saint Vincent and the Grenadines';
        '249'       = 'Venezuela';                '25'        = 'Bosnia and Herzegovina';   '251'       = 'Vietnam';
        '252'       = 'U.S. Virgin Islands';      '253'       = 'Vatican City';             '254'       = 'Namibia';
        '258'       = 'Wake Island';              '259'       = 'Samoa';                    '26'        = 'Bolivia';
        '260'       = 'Swaziland';                '261'       = 'Yemen';                    '26286'     = 'Polynesia';
        '263'       = 'Zambia';                   '264'       = 'Zimbabwe';                 '269'       = 'Serbia and Montenegro (Former)';
        '27'        = 'Myanmar';                  '270'       = 'Montenegro';               '27082'     = 'Central America';
        '271'       = 'Serbia';                   '27114'     = 'Oceania';                  '273'       = 'Curaçao';
        '276'       = 'South Sudan';              '28'        = 'Benin';                    '29'        = 'Belarus';
        '3'         = 'Afghanistan';              '30'        = 'Solomon Islands';          '300'       = 'Anguilla';
        '301'       = 'Antarctica';               '302'       = 'Aruba';                    '303'       = 'Ascension Island';
        '304'       = 'Ashmore and Cartier Islands'; '305'    = 'Baker Island';             '306'       = 'Bouvet Island';
        '307'       = 'Cayman Islands';           '308'       = 'Channel Islands';          '309'       = 'Christmas Island';
        '30967'     = 'Sint Maarten';             '310'       = 'Clipperton Island';        '311'       = 'Cocos (Keeling) Islands';
        '312'       = 'Cook Islands';             '313'       = 'Coral Sea Islands';        '31396'     = 'South America';
        '314'       = 'Diego Garcia';             '315'       = 'Falkland Islands';         '317'       = 'French Guiana';
        '31706'     = 'Saint Martin';             '318'       = 'French Polynesia';         '319'       = 'French Southern Territories';
        '32'        = 'Brazil';                   '321'       = 'Guadeloupe';               '322'       = 'Guam';
        '323'       = 'Guantanamo Bay';           '324'       = 'Guernsey';                 '325'       = 'Heard Island and McDonald Islands';
        '326'       = 'Howland Island';           '327'       = 'Jarvis Island';            '328'       = 'Jersey';
        '329'       = 'Kingman Reef';             '330'       = 'Martinique';               '331'       = 'Mayotte';
        '332'       = 'Montserrat';               '333'       = 'Netherlands Antilles (Former)'; '334' = 'New Caledonia';
        '335'       = 'Niue';                     '336'       = 'Norfolk Island';           '337'       = 'Northern Mariana Islands';
        '338'       = 'Palmyra Atoll';            '339'       = 'Pitcairn Islands';         '34'        = 'Bhutan';
        '340'       = 'Rota Island';              '341'       = 'Saipan';                   '342'       = 'South Georgia and the South Sandwich Islands';
        '343'       = 'St Helena, Ascension and Tristan da Cunha'; '346' = 'Tinian Island'; '347'       = 'Tokelau';
        '348'       = 'Tristan da Cunha';         '349'       = 'Turks and Caicos Islands'; '35'        = 'Bulgaria';
        '351'       = 'British Virgin Islands';   '352'       = 'Wallis and Futuna';        '37'        = 'Brunei';
        '38'        = 'Burundi';                  '39'        = 'Canada';                   '39070'     = 'World';
        '4'         = 'Algeria';                  '40'        = 'Cambodia';                 '41'        = 'Chad';
        '42'        = 'Sri Lanka';                '42483'     = 'Western Africa';           '42484'     = 'Middle Africa';
        '42487'     = 'Northern Africa';          '43'        = 'Congo';                    '44'        = 'Congo (DRC)';
        '45'        = 'China';                    '46'        = 'Chile';                    '47590'     = 'Central Asia';
        '47599'     = 'South-Eastern Asia';       '47600'     = 'Eastern Asia';             '47603'     = 'Eastern Africa';
        '47609'     = 'Eastern Europe';           '47610'     = 'Southern Europe';          '47611'     = 'Middle East';
        '47614'     = 'Southern Asia';            '49'        = 'Cameroon';                 '5'         = 'Azerbaijan';
        '50'        = 'Comoros';                  '51'        = 'Colombia';                 '54'        = 'Costa Rica';
        '55'        = 'Central African Republic'; '56'        = 'Cuba';                     '57'        = 'Cabo Verde';
        '59'        = 'Cyprus';                   '6'         = 'Albania';                  '61'        = 'Denmark';
        '62'        = 'Djibouti';                 '63'        = 'Dominica';                 '65'        = 'Dominican Republic';
        '66'        = 'Ecuador';                  '67'        = 'Egypt';                    '68'        = 'Ireland';
        '69'        = 'Equatorial Guinea';        '7'         = 'Armenia';                  '70'        = 'Estonia';
        '71'        = 'Eritrea';                  '72'        = 'El Salvador';              '7299303'   = 'Timor-Leste';
        '73'        = 'Ethiopia';                 '742'       = 'Africa';                   '75'        = 'Czech Republic';
        '77'        = 'Finland';                  '78'        = 'Fiji';                     '8'         = 'Andorra';
        '80'        = 'Micronesia';               '81'        = 'Faroe Islands';            '84'        = 'France';
        '86'        = 'Gambia';                   '87'        = 'Gabon';                    '88'        = 'Georgia';
        '89'        = 'Ghana';                    '9'         = 'Angola';                   '90'        = 'Gibraltar';
        '91'        = 'Grenada';                  '93'        = 'Greenland';                '94'        = 'Germany';
        '98'        = 'Greece';                   '99'        = 'Guatemala';                '9914689'   = 'Kosovo';
    }
    $languageLookup = @{
        'aa' = 'Afar'; 'aa-DJ' = 'Afar (Djibouti)'; 'aa-ER' = 'Afar (Eritrea)';
        'aa-ET' = 'Afar (Ethiopia)'; 'af' = 'Afrikaans'; 'af-NA' = 'Afrikaans (Namibia)';
        'af-ZA' = 'Afrikaans (South Africa)'; 'agq' = 'Aghem'; 'agq-CM' = 'Aghem (Cameroon)';
        'ak' = 'Akan'; 'ak-GH' = 'Akan (Ghana)'; 'am' = 'Amharic';
        'am-ET' = 'Amharic (Ethiopia)'; 'ar' = 'Arabic'; 'ar-001' = 'Arabic (World)';
        'ar-AE' = 'Arabic (U.A.E.)'; 'ar-BH' = 'Arabic (Bahrain)'; 'ar-DJ' = 'Arabic (Djibouti)';
        'ar-DZ' = 'Arabic (Algeria)'; 'ar-EG' = 'Arabic (Egypt)'; 'ar-ER' = 'Arabic (Eritrea)';
        'ar-IL' = 'Arabic (Israel)'; 'ar-IQ' = 'Arabic (Iraq)'; 'ar-JO' = 'Arabic (Jordan)';
        'ar-KM' = 'Arabic (Comoros)'; 'ar-KW' = 'Arabic (Kuwait)'; 'ar-LB' = 'Arabic (Lebanon)';
        'ar-LY' = 'Arabic (Libya)'; 'ar-MA' = 'Arabic (Morocco)'; 'ar-MR' = 'Arabic (Mauritania)';
        'ar-OM' = 'Arabic (Oman)'; 'ar-PS' = 'Arabic (Palestinian Authority)'; 'ar-QA' = 'Arabic (Qatar)';
        'ar-SA' = 'Arabic (Saudi Arabia)'; 'ar-SD' = 'Arabic (Sudan)'; 'ar-SO' = 'Arabic (Somalia)';
        'ar-SS' = 'Arabic (South Sudan)'; 'ar-SY' = 'Arabic (Syria)'; 'ar-TD' = 'Arabic (Chad)';
        'ar-TN' = 'Arabic (Tunisia)'; 'ar-YE' = 'Arabic (Yemen)'; 'arn' = 'Mapudungun';
        'arn-CL' = 'Mapudungun (Chile)'; 'as' = 'Assamese'; 'as-IN' = 'Assamese (India)';
        'asa' = 'Asu'; 'asa-TZ' = 'Asu (Tanzania)'; 'ast' = 'Asturian';
        'ast-ES' = 'Asturian (Spain)'; 'az' = 'Azerbaijani'; 'az-Cyrl' = 'Azerbaijani (Cyrillic)';
        'az-Cyrl-AZ' = 'Azerbaijani (Cyrillic, Azerbaijan)'; 'az-Latn' = 'Azerbaijani (Latin)'; 'az-Latn-AZ' = 'Azerbaijani (Latin, Azerbaijan)';
        'ba' = 'Bashkir'; 'ba-RU' = 'Bashkir (Russia)'; 'bas' = 'Basaa';
        'bas-CM' = 'Basaa (Cameroon)'; 'be' = 'Belarusian'; 'be-BY' = 'Belarusian (Belarus)';
        'bem' = 'Bemba'; 'bem-ZM' = 'Bemba (Zambia)'; 'bez' = 'Bena';
        'bez-TZ' = 'Bena (Tanzania)'; 'bg' = 'Bulgarian'; 'bg-BG' = 'Bulgarian (Bulgaria)';
        'bin' = 'Edo'; 'bin-NG' = 'Edo (Nigeria)'; 'bm' = 'Bambara';
        'bm-Latn' = 'Bambara (Latin)'; 'bm-Latn-ML' = 'Bambara (Latin, Mali)'; 'bn' = 'Bangla';
        'bn-BD' = 'Bangla (Bangladesh)'; 'bn-IN' = 'Bangla (India)'; 'bo' = 'Tibetan';
        'bo-CN' = 'Tibetan (PRC)'; 'bo-IN' = 'Tibetan (India)'; 'br' = 'Breton';
        'br-FR' = 'Breton (France)'; 'brx' = 'Bodo'; 'brx-IN' = 'Bodo (India)';
        'bs' = 'Bosnian'; 'bs-Cyrl' = 'Bosnian (Cyrillic)'; 'bs-Cyrl-BA' = 'Bosnian (Cyrillic, Bosnia and Herzegovina)';
        'bs-Latn' = 'Bosnian (Latin)'; 'bs-Latn-BA' = 'Bosnian (Latin, Bosnia and Herzegovina)'; 'byn' = 'Blin';
        'byn-ER' = 'Blin (Eritrea)'; 'ca' = 'Catalan'; 'ca-AD' = 'Catalan (Andorra)';
        'ca-ES' = 'Catalan (Catalan)'; 'ca-ES-valencia' = 'Valencian (Spain)'; 'ca-FR' = 'Catalan (France)';
        'ca-IT' = 'Catalan (Italy)'; 'ce' = 'Chechen'; 'ce-RU' = 'Chechen (Russia)';
        'cgg' = 'Chiga'; 'cgg-UG' = 'Chiga (Uganda)'; 'chr' = 'Cherokee';
        'chr-Cher' = 'Cherokee (Cherokee)'; 'chr-Cher-US' = 'Cherokee (Cherokee)'; 'co' = 'Corsican';
        'co-FR' = 'Corsican (France)'; 'cs' = 'Czech'; 'cs-CZ' = 'Czech (Czechia / Czech Republic)';
        'cu' = 'Church Slavic'; 'cu-RU' = 'Church Slavic (Russia)'; 'cy' = 'Welsh';
        'cy-GB' = 'Welsh (United Kingdom)'; 'da' = 'Danish'; 'da-DK' = 'Danish (Denmark)';
        'da-GL' = 'Danish (Greenland)'; 'dav' = 'Taita'; 'dav-KE' = 'Taita (Kenya)';
        'de' = 'German'; 'de-AT' = 'German (Austria)'; 'de-BE' = 'German (Belgium)';
        'de-CH' = 'German (Switzerland)'; 'de-DE' = 'German (Germany)'; 'de-IT' = 'German (Italy)';
        'de-LI' = 'German (Liechtenstein)'; 'de-LU' = 'German (Luxembourg)'; 'dje' = 'Zarma';
        'dje-NE' = 'Zarma (Niger)'; 'dsb' = 'Lower Sorbian'; 'dsb-DE' = 'Lower Sorbian (Germany)';
        'dua' = 'Duala'; 'dua-CM' = 'Duala (Cameroon)'; 'dv' = 'Divehi';
        'dv-MV' = 'Divehi (Maldives)'; 'dyo' = 'Jola-Fonyi'; 'dyo-SN' = 'Jola-Fonyi (Senegal)';
        'dz' = 'Dzongkha'; 'dz-BT' = 'Dzongkha (Bhutan)'; 'ebu' = 'Embu';
        'ebu-KE' = 'Embu (Kenya)'; 'ee' = 'Ewe'; 'ee-GH' = 'Ewe (Ghana)';
        'ee-TG' = 'Ewe (Togo)'; 'el' = 'Greek'; 'el-CY' = 'Greek (Cyprus)';
        'el-GR' = 'Greek (Greece)'; 'en' = 'English'; 'en-001' = 'English (World)';
        'en-029' = 'English (Caribbean)'; 'en-150' = 'English (Europe)'; 'en-AG' = 'English (Antigua and Barbuda)';
        'en-AI' = 'English (Anguilla)'; 'en-AS' = 'English (American Samoa)'; 'en-AT' = 'English (Austria)';
        'en-AU' = 'English (Australia)'; 'en-BB' = 'English (Barbados)'; 'en-BE' = 'English (Belgium)';
        'en-BI' = 'English (Burundi)'; 'en-BM' = 'English (Bermuda)'; 'en-BS' = 'English (Bahamas)';
        'en-BW' = 'English (Botswana)'; 'en-BZ' = 'English (Belize)'; 'en-CA' = 'English (Canada)';
        'en-CC' = 'English (Cocos [Keeling] Islands)'; 'en-CH' = 'English (Switzerland)'; 'en-CK' = 'English (Cook Islands)';
        'en-CM' = 'English (Cameroon)'; 'en-CX' = 'English (Christmas Island)'; 'en-CY' = 'English (Cyprus)';
        'en-DE' = 'English (Germany)'; 'en-DK' = 'English (Denmark)'; 'en-DM' = 'English (Dominica)';
        'en-ER' = 'English (Eritrea)'; 'en-FI' = 'English (Finland)'; 'en-FJ' = 'English (Fiji)';
        'en-FK' = 'English (Falkland Islands)'; 'en-FM' = 'English (Micronesia)'; 'en-GB' = 'English (United Kingdom)';
        'en-GD' = 'English (Grenada)'; 'en-GG' = 'English (Guernsey)'; 'en-GH' = 'English (Ghana)';
        'en-GI' = 'English (Gibraltar)'; 'en-GM' = 'English (Gambia)'; 'en-GU' = 'English (Guam)';
        'en-GY' = 'English (Guyana)'; 'en-HK' = 'English (Hong Kong SAR)'; 'en-ID' = 'English (Indonesia)';
        'en-IE' = 'English (Ireland)'; 'en-IL' = 'English (Israel)'; 'en-IM' = 'English (Isle of Man)';
        'en-IN' = 'English (India)'; 'en-IO' = 'English (British Indian Ocean Territory)'; 'en-JE' = 'English (Jersey)';
        'en-JM' = 'English (Jamaica)'; 'en-KE' = 'English (Kenya)'; 'en-KI' = 'English (Kiribati)';
        'en-KN' = 'English (Saint Kitts and Nevis)'; 'en-KY' = 'English (Cayman Islands)'; 'en-LC' = 'English (Saint Lucia)';
        'en-LR' = 'English (Liberia)'; 'en-LS' = 'English (Lesotho)'; 'en-MG' = 'English (Madagascar)';
        'en-MH' = 'English (Marshall Islands)'; 'en-MO' = 'English (Macao SAR)'; 'en-MP' = 'English (Northern Mariana Islands)';
        'en-MS' = 'English (Montserrat)'; 'en-MT' = 'English (Malta)'; 'en-MU' = 'English (Mauritius)';
        'en-MW' = 'English (Malawi)'; 'en-MY' = 'English (Malaysia)'; 'en-NA' = 'English (Namibia)';
        'en-NF' = 'English (Norfolk Island)'; 'en-NG' = 'English (Nigeria)'; 'en-NL' = 'English (Netherlands)';
        'en-NR' = 'English (Nauru)'; 'en-NU' = 'English (Niue)'; 'en-NZ' = 'English (New Zealand)';
        'en-PG' = 'English (Papua New Guinea)'; 'en-PH' = 'English (Philippines)'; 'en-PK' = 'English (Pakistan)';
        'en-PN' = 'English (Pitcairn Islands)'; 'en-PR' = 'English (Puerto Rico)'; 'en-PW' = 'English (Palau)';
        'en-RW' = 'English (Rwanda)'; 'en-SB' = 'English (Solomon Islands)'; 'en-SC' = 'English (Seychelles)';
        'en-SD' = 'English (Sudan)'; 'en-SE' = 'English (Sweden)'; 'en-SG' = 'English (Singapore)';
        'en-SH' = 'English (St Helena, Ascension, Tristan da Cunha)'; 'en-SI' = 'English (Slovenia)'; 'en-SL' = 'English (Sierra Leone)';
        'en-SS' = 'English (South Sudan)'; 'en-SX' = 'English (Sint Maarten)'; 'en-SZ' = 'English (Swaziland)';
        'en-TC' = 'English (Turks and Caicos Islands)'; 'en-TK' = 'English (Tokelau)'; 'en-TO' = 'English (Tonga)';
        'en-TT' = 'English (Trinidad and Tobago)'; 'en-TV' = 'English (Tuvalu)'; 'en-TZ' = 'English (Tanzania)';
        'en-UG' = 'English (Uganda)'; 'en-UM' = 'English (US Minor Outlying Islands)'; 'en-US' = 'English (United States)';
        'en-VC' = 'English (Saint Vincent and the Grenadines)'; 'en-VG' = 'English (British Virgin Islands)'; 'en-VI' = 'English (US Virgin Islands)';
        'en-VU' = 'English (Vanuatu)'; 'en-WS' = 'English (Samoa)'; 'en-ZA' = 'English (South Africa)';
        'en-ZM' = 'English (Zambia)'; 'en-ZW' = 'English (Zimbabwe)'; 'eo' = 'Esperanto';
        'eo-001' = 'Esperanto (World)'; 'es' = 'Spanish'; 'es-419' = 'Spanish (Latin America)';
        'es-AR' = 'Spanish (Argentina)'; 'es-BO' = 'Spanish (Bolivia)'; 'es-BR' = 'Spanish (Brazil)';
        'es-BZ' = 'Spanish (Belize)'; 'es-CL' = 'Spanish (Chile)'; 'es-CO' = 'Spanish (Colombia)';
        'es-CR' = 'Spanish (Costa Rica)'; 'es-CU' = 'Spanish (Cuba)'; 'es-DO' = 'Spanish (Dominican Republic)';
        'es-EC' = 'Spanish (Ecuador)'; 'es-ES' = 'Spanish (Spain)'; 'es-GQ' = 'Spanish (Equatorial Guinea)';
        'es-GT' = 'Spanish (Guatemala)'; 'es-HN' = 'Spanish (Honduras)'; 'es-MX' = 'Spanish (Mexico)';
        'es-NI' = 'Spanish (Nicaragua)'; 'es-PA' = 'Spanish (Panama)'; 'es-PE' = 'Spanish (Peru)';
        'es-PH' = 'Spanish (Philippines)'; 'es-PR' = 'Spanish (Puerto Rico)'; 'es-PY' = 'Spanish (Paraguay)';
        'es-SV' = 'Spanish (El Salvador)'; 'es-US' = 'Spanish (United States)'; 'es-UY' = 'Spanish (Uruguay)';
        'es-VE' = 'Spanish (Venezuela)'; 'et' = 'Estonian'; 'et-EE' = 'Estonian (Estonia)';
        'eu' = 'Basque'; 'eu-ES' = 'Basque (Basque)'; 'ewo' = 'Ewondo';
        'ewo-CM' = 'Ewondo (Cameroon)'; 'fa' = 'Persian'; 'fa-IR' = 'Persian (Iran)';
        'ff' = 'Fulah'; 'ff-CM' = 'Fulah (Cameroon)'; 'ff-GN' = 'Fulah (Guinea)';
        'ff-Latn' = 'Fulah (Latin)'; 'ff-Latn-SN' = 'Fulah (Latin, Senegal)'; 'ff-MR' = 'Fulah (Mauritania)';
        'ff-NG' = 'Fulah (Nigeria)'; 'fi' = 'Finnish'; 'fi-FI' = 'Finnish (Finland)';
        'fil' = 'Filipino'; 'fil-PH' = 'Filipino (Philippines)'; 'fo' = 'Faroese';
        'fo-DK' = 'Faroese (Denmark)'; 'fo-FO' = 'Faroese (Faroe Islands)'; 'fr' = 'French';
        'fr-029' = 'French (Caribbean)'; 'fr-BE' = 'French (Belgium)'; 'fr-BF' = 'French (Burkina Faso)';
        'fr-BI' = 'French (Burundi)'; 'fr-BJ' = 'French (Benin)'; 'fr-BL' = 'French (Saint Barthélemy)';
        'fr-CA' = 'French (Canada)'; 'fr-CD' = 'French (Congo DRC)'; 'fr-CF' = 'French (Central African Republic)';
        'fr-CG' = 'French (Congo)'; 'fr-CH' = 'French (Switzerland)'; 'fr-CI' = 'French (Côte dIvoire)';
        'fr-CM' = "French (Cameroon)"; "fr-DJ" = 'French (Djibouti)'; 'fr-DZ' = 'French (Algeria)';
        'fr-FR' = "French (France)"; "fr-GA" = 'French (Gabon)'; 'fr-GF' = 'French (French Guiana)';
        'fr-GN' = 'French (Guinea)'; 'fr-GP' = "French (Guadeloupe)"; "fr-GQ" = 'French (Equatorial Guinea)';
        'fr-HT' = "French (Haiti)"; "fr-KM" = 'French (Comoros)'; 'fr-LU' = 'French (Luxembourg)';
        "fr-MA" = "French (Morocco)"; 'fr-MC' = 'French (Monaco)'; 'fr-MF' = 'French (Saint Martin)';
        'fr-MG' = 'French (Madagascar)'; 'fr-ML' = "French (Mali)"; "fr-MQ" = 'French (Martinique)';
        'fr-MR' = "French (Mauritania)"; "fr-MU" = 'French (Mauritius)'; 'fr-NC' = 'French (New Caledonia)';
        'fr-NE' = "French (Niger)"; 'fr-PF' = "French (French Polynesia)"; 'fr-PM' = 'French (Saint Pierre and Miquelon)';
        'fr-RE' = "French (Reunion)"; 'fr-RW' = 'French (Rwanda)'; "fr-SC" = 'French (Seychelles)';
        'fr-SN' = "French (Senegal)"; "fr-SY" = 'French (Syria)'; 'fr-TD' = 'French (Chad)';
        'fr-TG' = 'French (Togo)'; 'fr-TN' = "French (Tunisia)"; "fr-VU" = 'French (Vanuatu)';
        'fr-WF' = "French (Wallis and Futuna)"; "fr-YT" = 'French (Mayotte)'; 'fur' = 'Friulian';
        'fur-IT' = "Friulian (Italy)"; "fy" = 'Frisian'; 'fy-NL' = 'Frisian (Netherlands)';
        'ga' = 'Irish'; 'ga-IE' = "Irish (Ireland)"; "gd" = 'Scottish Gaelic';
        'gd-GB' = "Scottish Gaelic (United Kingdom)"; "gl" = 'Galician'; 'gl-ES' = 'Galician (Galician)';
        'gn' = "Guarani"; "gn-PY" = 'Guarani (Paraguay)'; 'gsw' = 'Alsatian';
        'gsw-CH' = 'Alsatian (Switzerland)'; "gsw-FR" = "Alsatian (France)"; 'gsw-LI' = 'Alsatian (Liechtenstein)';
        'gu' = "Gujarati"; "gu-IN" = 'Gujarati (India)'; 'guz' = 'Gusii';
        'guz-KE' = "Gusii (Kenya)"; 'gv' = "Manx"; 'gv-IM' = 'Manx (Isle of Man)';
        'ha' = 'Hausa'; 'ha-Latn' = "Hausa (Latin)"; "ha-Latn-GH" = 'Hausa (Latin, Ghana)';
        'ha-Latn-NE' = "Hausa (Latin, Niger)"; "ha-Latn-NG" = 'Hausa (Latin, Nigeria)'; 'haw' = 'Hawaiian';
        'haw-US' = "Hawaiian (United States)"; "he" = 'Hebrew'; 'he-IL' = 'Hebrew (Israel)';
        'hi' = 'Hindi'; "hi-IN" = "Hindi (India)"; 'hr' = 'Croatian';
        'hr-BA' = "Croatian (Latin, Bosnia and Herzegovina)"; "hr-HR" = 'Croatian (Croatia)'; 'hsb' = 'Upper Sorbian';
        'hsb-DE' = "Upper Sorbian (Germany)"; 'hu' = "Hungarian"; 'hu-HU' = 'Hungarian (Hungary)';
        'hy' = 'Armenian'; 'hy-AM' = "Armenian (Armenia)"; "ia" = 'Interlingua';
        'ia-001' = "Interlingua (World)"; "ia-FR" = 'Interlingua (France)'; 'ibb' = 'Ibibio';
        'ibb-NG' = "Ibibio (Nigeria)"; "id" = 'Indonesian'; 'id-ID' = 'Indonesian (Indonesia)';
        'ig' = 'Igbo'; "ig-NG" = "Igbo (Nigeria)"; 'ii' = 'Yi';
        'ii-CN' = "Yi (PRC)"; "is" = 'Icelandic'; 'is-IS' = 'Icelandic (Iceland)';
        'it' = 'Italian'; "it-CH" = 'Italian (Switzerland)'; "it-IT" = 'Italian (Italy)';
        'it-SM' = 'Italian (San Marino)'; 'it-VA' = "Italian (Vatican City)"; "iu" = 'Inuktitut';
        "iu-Cans" = 'Inuktitut (Syllabics)'; "iu-Cans-CA" = 'Inuktitut (Syllabics, Canada)'; 'iu-Latn' = 'Inuktitut (Latin)';
        'iu-Latn-CA' = "Inuktitut (Latin, Canada)"; "ja" = 'Japanese'; 'ja-JP' = 'Japanese (Japan)';
        'jgo' = 'Ngomba'; 'jgo-CM' = "Ngomba (Cameroon)"; "jmc" = 'Machame';
        'jmc-TZ' = "Machame (Tanzania)"; "jv" = 'Javanese'; 'jv-Java' = 'Javanese (Javanese)';
        'jv-Java-ID' = "Javanese (Javanese, Indonesia)"; "jv-Latn" = 'Javanese'; 'jv-Latn-ID' = 'Javanese (Indonesia)';
        'ka' = 'Georgian'; 'ka-GE' = "Georgian (Georgia)"; "kab" = 'Kabyle';
        'kab-DZ' = "Kabyle (Algeria)"; "kam" = 'Kamba'; 'kam-KE' = 'Kamba (Kenya)';
        'kde' = "Makonde"; "kde-TZ" = 'Makonde (Tanzania)'; 'kea' = 'Kabuverdianu';
        'kea-CV' = 'Kabuverdianu (Cabo Verde)'; "khq" = "Koyra Chiini"; 'khq-ML' = 'Koyra Chiini (Mali)';
        'ki' = "Kikuyu"; "ki-KE" = 'Kikuyu (Kenya)'; 'kk' = 'Kazakh';
        'kk-KZ' = "Kazakh (Kazakhstan)"; "kkj" = 'Kako'; 'kkj-CM' = 'Kako (Cameroon)';
        'kl' = 'Greenlandic'; 'kl-GL' = "Greenlandic (Greenland)"; "kln" = 'Kalenjin';
        'kln-KE' = "Kalenjin (Kenya)"; "km" = 'Khmer'; 'km-KH' = 'Khmer (Cambodia)';
        'kn' = "Kannada"; "kn-IN" = 'Kannada (India)'; 'ko' = 'Korean';
        'ko-KP' = 'Korean (North Korea)'; "ko-KR" = "Korean (Korea)"; 'kok' = 'Konkani';
        'kok-IN' = "Konkani (India)"; "kr" = 'Kanuri'; 'kr-NG' = 'Kanuri (Nigeria)';
        'ks' = 'Kashmiri'; "ks-Arab" = "Kashmiri (Perso-Arabic)"; 'ks-Arab-IN' = 'Kashmiri (Perso-Arabic)';
        'ks-Deva' = 'Kashmiri (Devanagari)'; 'ks-Deva-IN' = "Kashmiri (Devanagari, India)"; "ksb" = 'Shambala';
        'ksb-TZ' = "Shambala (Tanzania)"; "ksf" = 'Bafia'; 'ksf-CM' = 'Bafia (Cameroon)';
        'ksh' = "Colognian"; "ksh-DE" = 'Ripuarian (Germany)'; 'ku' = 'Central Kurdish';
        'ku-Arab' = 'Central Kurdish (Arabic)'; "ku-Arab-IQ" = "Central Kurdish (Iraq)"; 'ku-Arab-IR' = 'Kurdish (Perso-Arabic, Iran)';
        'kw' = "Cornish"; "kw-GB" = 'Cornish (United Kingdom)'; 'ky' = 'Kyrgyz';
        'ky-KG' = 'Kyrgyz (Kyrgyzstan)'; 'la' = "Latin"; "la-001" = 'Latin (World)';
        'lag' = 'Langi'; 'lag-TZ' = "Langi (Tanzania)"; "lb" = 'Luxembourgish';
        "lb-LU" = 'Luxembourgish (Luxembourg)'; "lg" = 'Ganda'; 'lg-UG' = 'Ganda (Uganda)';
        'lkt' = "Lakota"; "lkt-US" = 'Lakota (United States)'; 'ln' = 'Lingala';
        'ln-AO' = 'Lingala (Angola)'; 'ln-CD' = "Lingala (Congo DRC)"; "ln-CF" = 'Lingala (Central African Republic)';
        'ln-CG' = "Lingala (Congo)"; "lo" = 'Lao'; 'lo-LA' = 'Lao (Lao P.D.R.)';
        'lrc' = "Northern Luri"; "lrc-IQ" = 'Northern Luri (Iraq)'; 'lrc-IR' = 'Northern Luri (Iran)';
        'lt' = 'Lithuanian'; 'lt-LT' = "Lithuanian (Lithuania)"; "lu" = 'Luba-Katanga';
        'lu-CD' = "Luba-Katanga (Congo DRC)"; "luo" = 'Luo'; 'luo-KE' = 'Luo (Kenya)';
        'luy' = "Luyia"; "luy-KE" = 'Luyia (Kenya)'; 'lv' = 'Latvian';
        'lv-LV' = 'Latvian (Latvia)'; "mas" = "Masai"; 'mas-KE' = 'Masai (Kenya)';
        'mas-TZ' = 'Masai (Tanzania)'; "mer" = 'Meru'; "mer-KE" = 'Meru (Kenya)';
        'mfe' = 'Morisyen'; "mfe-MU" = "Morisyen (Mauritius)"; 'mg' = 'Malagasy';
        'mg-MG' = 'Malagasy (Madagascar)'; 'mgh' = "Makhuwa-Meetto"; "mgh-MZ" = 'Makhuwa-Meetto (Mozambique)';
        'mgo' = "Meta'"; 'mgo-CM' = "Meta' (Cameroon)"; 'mi' = 'Maori';
        'mi-NZ' = "Maori (New Zealand)"; "mk" = 'Macedonian (FYROM)'; 'mk-MK' = 'Macedonian (Former Yugoslav Republic of Macedonia)';
        'ml' = 'Malayalam'; "ml-IN" = "Malayalam (India)"; 'mn' = 'Mongolian';
        "mn-Cyrl" = 'Mongolian (Cyrillic)'; "mn-MN" = 'Mongolian (Cyrillic, Mongolia)'; 'mn-Mong' = 'Mongolian (Traditional Mongolian)';
        'mn-Mong-CN' = 'Mongolian (Traditional Mongolian, PRC)'; "mn-Mong-MN" = 'Mongolian (Traditional Mongolian, Mongolia)'; "mni" = 'Manipuri';
        'mni-IN' = "Manipuri (India)"; 'moh' = "Mohawk"; 'moh-CA' = 'Mohawk (Mohawk)';
        'mr' = 'Marathi'; "mr-IN" = "Marathi (India)"; 'ms' = 'Malay';
        "ms-BN" = "Malay (Brunei Darussalam)"; 'ms-MY' = 'Malay (Malaysia)'; 'ms-SG' = 'Malay (Latin, Singapore)';
        'mt' = 'Maltese'; 'mt-MT' = "Maltese (Malta)"; "mua" = 'Mundang';
        'mua-CM' = 'Mundang (Cameroon)'; 'my' = "Burmese"; "my-MM" = 'Burmese (Myanmar)';
        'mzn' = "Mazanderani"; 'mzn-IR' = 'Mazanderani (Iran)'; "naq" = 'Nama';
        'naq-NA' = 'Nama (Namibia)'; 'nb' = 'Norwegian (Bokmål)'; "nb-NO" = "Norwegian, Bokmål (Norway)";
        'nb-SJ' = "Norwegian, Bokmål (Svalbard and Jan Mayen)"; "nd" = 'North Ndebele'; 'nd-ZW' = 'North Ndebele (Zimbabwe)';
        'nds' = "Low German"; "nds-DE" = 'Low German (Germany)'; 'nds-NL' = 'Low German (Netherlands)';
        'ne' = 'Nepali'; 'ne-IN' = "Nepali (India)"; "ne-NP" = 'Nepali (Nepal)';
        "nl" = 'Dutch'; "nl-AW" = 'Dutch (Aruba)'; 'nl-BE' = 'Dutch (Belgium)';
        "nl-BQ" = "Dutch (Bonaire, Sint Eustatius and Saba)"; 'nl-CW' = 'Dutch (Curaçao)'; 'nl-NL' = 'Dutch (Netherlands)';
        'nl-SR' = 'Dutch (Suriname)'; 'nl-SX' = "Dutch (Sint Maarten)"; "nmg" = 'Kwasio';
        'nmg-CM' = "Kwasio (Cameroon)"; "nn" = 'Norwegian (Nynorsk)'; 'nn-NO' = 'Norwegian, Nynorsk (Norway)';
        "nnh" = "Ngiemboon"; 'nnh-CM' = 'Ngiemboon (Cameroon)'; 'no' = 'Norwegian';
        'nqo' = "N'ko"; 'nqo-GN' = "N'ko (Guinea)"; 'nr' = 'South Ndebele';
        "nr-ZA" = 'South Ndebele (South Africa)'; "nso" = 'Sesotho sa Leboa'; 'nso-ZA' = 'Sesotho sa Leboa (South Africa)';
        "nus" = "Nuer"; 'nus-SS' = 'Nuer (South Sudan)'; 'nyn' = 'Nyankole';
        'nyn-UG' = 'Nyankole (Uganda)'; 'oc' = "Occitan"; "oc-FR" = 'Occitan (France)';
        "om" = 'Oromo'; "om-ET" = 'Oromo (Ethiopia)'; 'om-KE' = 'Oromo (Kenya)';
        "or" = "Odia"; 'or-IN' = 'Odia (India)'; 'os' = 'Ossetic';
        'os-GE' = 'Ossetian (Cyrillic, Georgia)'; 'os-RU' = "Ossetian (Cyrillic, Russia)"; "pa" = 'Punjabi';
        'pa-Arab' = "Punjabi (Arabic)"; "pa-Arab-PK" = 'Punjabi (Islamic Republic of Pakistan)'; 'pa-IN' = 'Punjabi (India)';
        'pap' = "Papiamento"; "pap-029" = 'Papiamento (Caribbean)'; 'pl' = 'Polish';
        'pl-PL' = 'Polish (Poland)'; 'prg' = "Prussian"; "prg-001" = 'Prussian (World)';
        "prs" = "Dari"; 'prs-AF' = 'Dari (Afghanistan)'; 'ps' = 'Pashto';
        'ps-AF' = "Pashto (Afghanistan)"; "pt" = 'Portuguese'; 'pt-AO' = 'Portuguese (Angola)';
        'pt-BR' = "Portuguese (Brazil)"; "pt-CH" = 'Portuguese (Switzerland)'; 'pt-CV' = 'Portuguese (Cabo Verde)';
        'pt-GQ' = "Portuguese (Equatorial Guinea)"; "pt-GW" = 'Portuguese (Guinea-Bissau)'; 'pt-LU' = 'Portuguese (Luxembourg)';
        'pt-MO' = "Portuguese (Macao SAR)"; "pt-MZ" = 'Portuguese (Mozambique)'; 'pt-PT' = 'Portuguese (Portugal)';
        'pt-ST' = 'Portuguese (São Tomé and Príncipe)'; "pt-TL" = 'Portuguese (Timor-Leste)'; 'quc' = "K'iche'";
        'quc-Latn' = "K'iche'"; 'quc-Latn-GT' = "K'iche' (Guatemala)"; 'quz' = 'Quechua';
        "quz-BO" = "Quechua (Bolivia)"; 'quz-EC' = 'Quechua (Ecuador)'; 'quz-PE' = 'Quechua (Peru)';
        'rm' = 'Romansh'; "rm-CH" = "Romansh (Switzerland)"; 'rn' = 'Rundi';
        "rn-BI" = 'Rundi (Burundi)'; "ro" = 'Romanian'; 'ro-MD' = 'Romanian (Moldova)';
        "ro-RO" = "Romanian (Romania)"; 'rof' = 'Rombo'; 'rof-TZ' = 'Rombo (Tanzania)';
        'ru' = 'Russian'; 'ru-BY' = "Russian (Belarus)"; "ru-KG" = 'Russian (Kyrgyzstan)';
        "ru-KZ" = 'Russian (Kazakhstan)'; "ru-MD" = 'Russian (Moldova)'; 'ru-RU' = 'Russian (Russia)';
        "ru-UA" = "Russian (Ukraine)"; 'rw' = 'Kinyarwanda'; 'rw-RW' = 'Kinyarwanda (Rwanda)';
        "rwk" = 'Rwa'; 'rwk-TZ' = "Rwa (Tanzania)"; 'sa' = 'Sanskrit';
        'sa-IN' = "Sanskrit (India)"; "sah" = 'Sakha'; 'sah-RU' = 'Sakha (Russia)';
        'saq' = "Samburu"; 'saq-KE' = 'Samburu (Kenya)'; "sbp" = 'Sangu';
        'sbp-TZ' = 'Sangu (Tanzania)'; 'sd' = "Sindhi"; "sd-Arab" = 'Sindhi (Arabic)';
        "sd-Arab-PK" = 'Sindhi (Islamic Republic of Pakistan)'; "sd-Deva" = 'Sindhi (Devanagari)'; 'sd-Deva-IN' = 'Sindhi (Devanagari, India)';
        "se" = "Sami (Northern)"; 'se-FI' = 'Sami, Northern (Finland)'; 'se-NO' = 'Sami, Northern (Norway)';
        'se-SE' = 'Sami, Northern (Sweden)'; 'seh' = "Sena"; "seh-MZ" = 'Sena (Mozambique)';
        "ses" = 'Koyraboro Senni'; "ses-ML" = 'Koyraboro Senni (Mali)'; 'sg' = 'Sango';
        'sg-CF' = "Sango (Central African Republic)"; "shi" = 'Tachelhit'; 'shi-Latn' = 'Tachelhit (Latin)';
        'shi-Latn-MA' = 'Tachelhit (Latin, Morocco)'; 'shi-Tfng' = "Tachelhit (Tifinagh)"; "shi-Tfng-MA" = 'Tachelhit (Tifinagh, Morocco)';
        "si" = 'Sinhala'; "si-LK" = 'Sinhala (Sri Lanka)'; 'sk' = 'Slovak';
        'sk-SK' = 'Slovak (Slovakia)'; "sl" = "Slovenian"; 'sl-SI' = 'Slovenian (Slovenia)';
        'sma' = "Sami (Southern)"; "sma-NO" = 'Sami, Southern (Norway)'; 'sma-SE' = 'Sami, Southern (Sweden)';
        'smj' = "Sami (Lule)"; "smj-NO" = 'Sami, Lule (Norway)'; 'smj-SE' = 'Sami, Lule (Sweden)';
        "smn" = 'Sami (Inari)'; 'smn-FI' = 'Sami, Inari (Finland)'; "sms" = 'Sami (Skolt)';
        'sms-FI' = 'Sami, Skolt (Finland)'; 'sn' = 'Shona'; "sn-Latn" = "Shona (Latin)";
        'sn-Latn-ZW' = "Shona (Latin, Zimbabwe)"; "so" = 'Somali'; 'so-DJ' = 'Somali (Djibouti)';
        'so-ET' = "Somali (Ethiopia)"; "so-KE" = 'Somali (Kenya)'; 'so-SO' = 'Somali (Somalia)';
        'sq' = 'Albanian'; "sq-AL" = "Albanian (Albania)"; 'sq-MK' = 'Albanian (Macedonia, FYRO)';
        'sq-XK' = "Albanian (Kosovo)"; "sr" = 'Serbian'; 'sr-Cyrl' = 'Serbian (Cyrillic)';
        'sr-Cyrl-BA' = 'Serbian (Cyrillic, Bosnia and Herzegovina)'; "sr-Cyrl-ME" = "Serbian (Cyrillic, Montenegro)"; 'sr-Cyrl-RS' = 'Serbian (Cyrillic, Serbia)';
        'sr-Cyrl-XK' = 'Serbian (Cyrillic, Kosovo)'; "sr-Latn" = "Serbian (Latin)"; 'sr-Latn-BA' = 'Serbian (Latin, Bosnia and Herzegovina)';
        'sr-Latn-ME' = "Serbian (Latin, Montenegro)"; "sr-Latn-RS" = 'Serbian (Latin, Serbia)'; 'sr-Latn-XK' = 'Serbian (Latin, Kosovo)';
        'ss' = "Swati"; "ss-SZ" = 'Swati (Eswatini former Swaziland)'; 'ss-ZA' = 'Swati (South Africa)';
        'ssy' = 'Saho'; "ssy-ER" = "Saho (Eritrea)"; 'st' = 'Southern Sotho';
        'st-LS' = 'Sesotho (Lesotho)'; "st-ZA" = "Southern Sotho (South Africa)"; 'sv' = 'Swedish';
        'sv-AX' = 'Swedish (Åland Islands)'; "sv-FI" = 'Swedish (Finland)'; "sv-SE" = 'Swedish (Sweden)';
        'sw' = 'Kiswahili'; "sw-CD" = "Kiswahili (Congo DRC)"; 'sw-KE' = 'Kiswahili (Kenya)';
        'sw-TZ' = "Kiswahili (Tanzania)"; "sw-UG" = 'Kiswahili (Uganda)'; 'syr' = 'Syriac';
        'syr-SY' = "Syriac (Syria)"; "ta" = 'Tamil'; 'ta-IN' = 'Tamil (India)';
        'ta-LK' = 'Tamil (Sri Lanka)'; "ta-MY" = "Tamil (Malaysia)"; 'ta-SG' = 'Tamil (Singapore)';
        'te' = 'Telugu'; "te-IN" = "Telugu (India)"; 'teo' = 'Teso';
        'teo-KE' = "Teso (Kenya)"; "teo-UG" = 'Teso (Uganda)'; 'tg' = 'Tajik';
        'tg-Cyrl' = 'Tajik (Cyrillic)'; "tg-Cyrl-TJ" = "Tajik (Cyrillic, Tajikistan)"; 'th' = 'Thai';
        'th-TH' = "Thai (Thailand)"; "ti" = 'Tigrinya'; 'ti-ER' = 'Tigrinya (Eritrea)';
        'ti-ET' = "Tigrinya (Ethiopia)"; "tig" = 'Tigre'; 'tig-ER' = 'Tigre (Eritrea)';
        'tk' = 'Turkmen'; 'tk-TM' = "Turkmen (Turkmenistan)"; "tn" = 'Setswana';
        'tn-BW' = 'Setswana (Botswana)'; "tn-ZA" = 'Setswana (South Africa)'; "to" = 'Tongan';
        'to-TO' = 'Tongan (Tonga)'; 'tr' = "Turkish"; "tr-CY" = 'Turkish (Cyprus)';
        'tr-TR' = 'Turkish (Turkey)'; "ts" = "Tsonga"; 'ts-ZA' = 'Tsonga (South Africa)';
        'tt' = 'Tatar'; "tt-RU" = "Tatar (Russia)"; 'twq' = 'Tasawaq';
        "twq-NE" = "Tasawaq (Niger)"; 'tzm' = 'Tamazight'; 'tzm-Arab' = 'Central Atlas Tamazight (Arabic)';
        'tzm-Arab-MA' = 'Central Atlas Tamazight (Arabic, Morocco)'; "tzm-Latn" = "Tamazight (Latin)"; 'tzm-Latn-DZ' = 'Tamazight (Latin, Algeria)';
        'tzm-Latn-MA' = 'Central Atlas Tamazight (Latin, Morocco)'; 'tzm-Tfng' = "Tamazight (Tifinagh)"; "tzm-Tfng-MA" = 'Central Atlas Tamazight (Tifinagh, Morocco)';
        "ug" = "Uyghur"; 'ug-CN' = 'Uyghur (PRC)'; 'uk' = 'Ukrainian';
        'uk-UA' = 'Ukrainian (Ukraine)'; "ur" = "Urdu"; 'ur-IN' = 'Urdu (India)';
        'ur-PK' = 'Urdu (Islamic Republic of Pakistan)'; 'uz' = "Uzbek"; "uz-Arab" = 'Uzbek (Perso-Arabic)';
        "uz-Arab-AF" = "Uzbek (Perso-Arabic, Afghanistan)"; 'uz-Cyrl' = 'Uzbek (Cyrillic)'; 'uz-Cyrl-UZ' = 'Uzbek (Cyrillic, Uzbekistan)';
        'uz-Latn' = 'Uzbek (Latin)'; "uz-Latn-UZ" = "Uzbek (Latin, Uzbekistan)"; 'vai' = 'Vai';
        'vai-Latn' = 'Vai (Latin)'; 'vai-Latn-LR' = "Vai (Latin, Liberia)"; "vai-Vaii" = 'Vai (Vai)';
        'vai-Vaii-LR' = "Vai (Vai, Liberia)"; "ve" = 'Venda'; 've-ZA' = 'Venda (South Africa)';
        'vi' = 'Vietnamese'; "vi-VN" = "Vietnamese (Vietnam)"; 'vo' = 'Volapük';
        'vo-001' = 'Volapük (World)'; "vun" = "Vunjo"; 'vun-TZ' = 'Vunjo (Tanzania)';
        'wae' = "Walser"; "wae-CH" = 'Walser (Switzerland)'; 'wal' = 'Wolaytta';
        'wal-ET' = 'Wolaytta (Ethiopia)'; "wo" = "Wolof"; 'wo-SN' = 'Wolof (Senegal)';
        'xh' = "isiXhosa"; 'xh-ZA' = "isiXhosa (South Africa)"; 'xog' = 'Soga';
        'xog-UG' = "Soga (Uganda)"; "yav" = 'Yangben'; 'yav-CM' = 'Yangben (Cameroon)';
        'yi' = 'Yiddish'; "yi-001" = "Yiddish (World)"; 'yo' = 'Yoruba';
        'yo-BJ' = "Yoruba (Benin)"; "yo-NG" = 'Yoruba (Nigeria)'; 'zgh' = 'Standard Moroccan Tamazight';
        'zgh-Tfng' = 'Standard Moroccan Tamazight (Tifinagh)'; "zgh-Tfng-MA" = "Standard Moroccan Tamazight (Tifinagh, Morocco)"; 'zh' = 'Chinese';
        'zh-CN' = 'Chinese (Simplified, PRC)'; "zh-Hans" = 'Chinese (Simplified)'; "zh-Hans-HK" = 'Chinese (Simplified Han, Hong Kong SAR)';
        'zh-Hans-MO' = 'Chinese (Simplified Han, Macao SAR)'; "zh-Hant" = "Chinese (Traditional)"; 'zh-HK' = 'Chinese (Traditional, Hong Kong S.A.R.)';
        'zh-MO' = 'Chinese (Traditional, Macao S.A.R.)'; "zh-SG" = 'Chinese (Simplified, Singapore)'; "zh-TW" = 'Chinese (Traditional, Taiwan)';
        'zu' = 'isiZulu'; 'zu-ZA' = 'isiZulu (South Africa)';
    }

    # Get the current user's language and region using the registry
    $Region = $localeLookup[(Get-ItemProperty -Path 'HKCU:Control Panel\International\Geo').Nation]
    # Iterate through registry key in case multiple languages are configured
    (Get-ItemProperty -Path 'HKCU:Control Panel\International\User Profile').Languages | ForEach-Object {
        $Languages += " - $($languageLookup[$_])"
    }

    return @{
        title   = 'Locale'
        content = "$Region$Languages"
    }
}
# <<===================<< Locale (.NET)
function info_locale_net {
    # Get the current region (location) from .NET which saves a few MS over the registry
    $RegionInfo = [System.Globalization.RegionInfo]::CurrentRegion.DisplayName
    
    # NOTE: The current CultureInfo (language) can be found in the static CurrentCulture property, but it only reflects the
    #   active one as opposed to all installed languages
    # $Culture = [System.Globalization.CultureInfo]::CurrentCulture
    
    # Get the current user's available languages using the registry
    # Iterate through registry key in case multiple languages are configured
    (Get-ItemProperty -Path 'HKCU:\Control Panel\International\User Profile').Languages | ForEach-Object {
        # Retrieve the language name from CultureInfo
        $languagecode = $_
        try {
            # Cross-reference the language code with the CultureInfo DisplayName
            $languagename = [System.Globalization.CultureInfo]::GetCultureInfo($languagecode).DisplayName
            $Languages += " - $languagename"
        } catch {
            # if not found, just display the code
            $Languages += " - $languagecode"
        }
    }
    return @{
        title   = 'Locale'
        content = "$RegionInfo$Languages"
    }
}
# <<===================<< Timezone
function info_timezone_net {
    # $TimeZone = Get-TimeZone
    $TimeZone = [System.TimeZoneInfo]::Local
    return @{
        title   = 'Timezone'
        content = $TimeZone.DisplayName
    }
}
function info_timezone_wmi {
    $TimeZone = gcim Win32_TimeZone -CimSession $cimSession | select StandardName,Caption
    return @{
        title   = 'Timezone'
        content = $TimeZone.Caption
    }
}
function info_cpu_reg1 {
    $CPUName = Get-ItemPropertyValue -Path 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0' -Name ProcessorNameString
    $CPUSpeed = Get-ItemPropertyValue -Path 'HKLM:\HARDWARE\DESCRIPTION\System\CentralProcessor\0' -Name '~MHz'
    return @{
        title   = 'CPU'
        content = '{0}, {1:n2}GHz' -f $CPUName, ($CPUSpeed / 1000)
    }
}
function info_cpu_reg2 {
    $CPUKey = [Microsoft.Win32.RegistryKey]::OpenBaseKey('LocalMachine', 'Default').OpenSubKey('HARDWARE\DESCRIPTION\System\CentralProcessor\0')
    $CPUName = $CPUKey.GetValue('ProcessorNameString')
    $CPUSpeed = $CPUKey.GetValue('~MHz')
    return @{
        title   = 'CPU'
        content = '{0}, {1:n2}GHz' -f $CPUName, ($CPUSpeed / 1000)
    }
}
function info_colorbar {
    return @(
        @{
            title   = ""
            content = ('{0}[0;40m{1}{0}[0;41m{1}{0}[0;42m{1}{0}[0;43m{1}{0}[0;44m{1}{0}[0;45m{1}{0}[0;46m{1}{0}[0;47m{1}{0}[0m') -f $e, '   '
        },
        @{
            title   = ""
            content = ('{0}[0;100m{1}{0}[0;101m{1}{0}[0;102m{1}{0}[0;103m{1}{0}[0;104m{1}{0}[0;105m{1}{0}[0;106m{1}{0}[0;107m{1}{0}[0m') -f $e, '   '
        }
    )
}
function info_colorbar_gen {
    $ColorsBG = 40..47
    $ColorsBG2 = 100..107
    $Content1 = ''
    $Content2 = ''
    for ($i = $ColorsBG[0]; $i -lt $ColorsBG[-1]; $i++) {
        $Content1 += "${e}[0;${i}m   "
    }
    $Content1 += "${e}[0m"
    for ($i = $ColorsBG2[0]; $i -lt $ColorsBG2[-1]; $i++) {
        $Content2 += "${e}[0;${i}m   "
    }
    $Content2 += "${e}[0m"
    $Return = @(
        @{
            title   = ''
            content = $Content1
        },
        @{
            title   = ''
            content = $Content2
        }
    )
    return $Return
}

# PSPT Profile: 391ms vs 478ms, 17 vs 91
# Measure: 11 vs 55, 1 vs. 202
# info_resolution_net # 391, 17, 11, 1
# info_resolution_wmi # 478, 91, 55, 202
# PSPT Profile: 118ms vs 20859 (?), 86 vs 789
# Measure: 21 vs. 17, 1 vs. 3
# info_locale_net # 118, 86, 21, 1
# info_locale_reg # 20859, 789, 17, 3
# PSPT Profile: 97ms vs 105ms, 15 vs 58
# Measure: 21 vs. 117, 2 vs. 19
# info_timezone_net # 97, 15, 21, 2
# info_timezone_wmi # 105, 58, 117, 19

$config = @(
    'resolution_net' #  1.81 avg
    'resolution_wmi' # 74.67 avg
    'locale_net'     #  0.52 avg
    'locale_reg'     #  4.82 avg
    'timezone_net'   #  2.05 avg
    'timezone_wmi'   # 11.20 avg
    'cpu_reg1'
    'cpu_reg2'
    'colorbar'
    'colorbar_gen'
)
# item = individual function name
# output = function result
# results = Command = item, Output = output, Time = execution time

function test-main {
    # Initialize an array to store the results
    $results = @()
    
    # Iterate through each command in $Cmds
    foreach ($item in $config) {
        # Initialize variables to store total execution time and output
        $totalExecutionTime = 0
        $output = $null
    
        # Run each command 10 times
        for ($i = 0; $i -lt 10; $i++) {
            $executionTime = Measure-Command {
                $output = & "info_$item"
            }
            $totalExecutionTime += $executionTime.TotalMilliseconds
        }
    
        # Calculate the average execution time
        $averageExecutionTime = $totalExecutionTime / 10
    
        # Store the output and average execution time in the results array
        $results += [pscustomobject]@{
            Command       = $cmd
            Output        = $output.content
            ExecutionTime = [math]::Round($averageExecutionTime, 2)
        }
    }
    
    # Output the results
    $results | ogv
}

# NOTE: passing the function body with both using: and function: works
# $jobtest = Start-Job -Name 'info_test' -ScriptBlock { & ([scriptblock]::Create(${using:function:info_timezone_net})) }
# NOTE: Dynamic function call works by passing the function name as a string and expanding with iex
# BUG: But... because the function has to be re-defined, it likely isn't a net performance gain
# $Functionname = 'info_timezone_net'
$jobtest = Start-Job -Name 'info_test' -ArgumentList $(Invoke-Expression "`$function:$Functionname") -ScriptBlock { param($func) Invoke-Expression $func }

function test-mta {
    $results = @()

    # run each command in a separate thread
    foreach ($item in $config) {
        $funcname = "info_$item"
        $splat = @{
            Name          = $funcname
            ArgumentList  = $(Invoke-Expression "`$function:$funcname")
            ScriptBlock   = {
                param($func)
                Invoke-Expression $func
            }
            ThrottleLimit = 5
        }
        if(Test-Path $funcname) {
            $ThreadJob = Start-ThreadJob @splat
        } else {
            $results += [pscustomobject]@{
                Command       = "$e[31mfunction '$funcname' not found"
                Output        = $null
                ExecutionTime = 0
            }
        }
    }
    
    # Wait for all jobs to complete
    $jobs = Get-Job -Name info_*
    $jobs | Wait-Job

    # Process each job result
    foreach ($job in $jobs) {
        $infotime = $job.PSEndTime.Value - $job.PSBeginTime.Value
        $timetotal += $infotime
        $info = Receive-Job -Job $job
        Remove-Job -Job $job

        # Calculate the average execution time
        $averageExecutionTime = $timetotal / 10
    
        # Store the output and average execution time in the results array
        $results += [pscustomobject]@{
            Command       = $cmd
            Output        = $info
            ExecutionTime = [math]::Round($averageExecutionTime, 2)
        }
    }
    $results
}

$cimSession | Remove-CimSession