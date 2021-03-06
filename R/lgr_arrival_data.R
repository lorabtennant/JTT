library(tidyverse)
library(fisheR)
library(lubridate)

# lists
migration_year <- '2020'
lgr_sites <- c('GRJ', 'GRA', 'GRS')  #(for obs_site filter: juv, adult, spill)
npth_chinook_sites <- c('BCCAP', 'CEFLAF', 'CJRAP', 'NLVP', 'LUGUAF', 'NPTH', 'PLAP', 'KOOS', 'MEADOC', 'NEWSOC') 
steelhead_sites <- c('IMNTRP','LSHEEF', 'JOHTRP', 'SECTRP', 'LOLOC', 'CLWRSF', 'NEWSOC','MEAD2C')
chinook_sites <- c('IMNTRP', 'IMNAHR', 'IMNAHW', 'JOHTRP', 'JOHNSC', 'SECTRP', 'LOLOC', 'CLWRSF',
                   'LOSTIP', 'LOSTIR', 'CLWR', npth_chinook_sites)
fchn_clearwater <- c('CLWR','NLVP','NPTH','CEFLAF','BCCAP','LUGUAF')
fchn_snake <- c('PLAP','CJRAP')

# MY 2020 start and end dates (filters) ----
# Beach Seining
sein_start <- mdy('06/16/2020')
sein_end <- mdy('08/13/2020')
# RST operation dates
johtrp_start <- mdy('05/23/2019')
johtrp_end <- mdy('06/14/2020')

imntrp_start <- mdy('10/04/2019')
imntrp_end <- mdy('07/12/2020')

sectrp_start <- mdy('06/24/2019')
sectrp_end <- mdy('11/11/2019') # no spring trapping

loloc_start <- mdy('09/29/2019')
loloc_end <- mdy('06/21/2020')

clwrsf_start <- mdy('09/26/2019')
clwrsf_end <- mdy('06/21/2020')


# DART data retrieval ----
# sth_dart <- steelhead_sites %>%
#   map_dfr(.f = ~{
#     get_PITobs(
#       query_type = 'release_site',
#       release_site = .x,
#       species = 'Steelhead',
#       run = 'All',
#       start_date = paste0('01/01/', migration_year),
#       end_date = paste0('12/31/', migration_year))  %>%
#       mutate(across(everything(), as.character))
#   })
# save(sth_dart, file = './data/arrival/sth_dart.rda')

# chn_dart <- chinook_sites %>%
#   map_dfr(.f = ~{
#     get_PITobs(
#       query_type = 'release_site',
#       release_site = .x,
#       species = 'Chinook',
#       run = 'All',
#       start_date = '01/01/2020',
#       end_date = '12/31/2020')  %>%
#       mutate(across(everything(), as.character))
#   })
# save(chn_dart, file = './data/arrival/chn_dart.rda')

load('./data/arrival/sth_dart.rda')
load('./data/arrival/chn_dart.rda')

# combine and process data ----
dart_my20 <- bind_rows(sth_dart, chn_dart) %>%
  separate(obs_time, into=c('obs_date', 'obs_time'), sep = ' ') %>%
  mutate(across(c(release_date, obs_date), ymd)) %>%
  mutate(tag_coord = str_extract(tag_file, '^[A-Z]{3}')) %>%
  mutate(run = if_else(sprrt == '15W', 'Fall', run)) %>%  # include 15W as Fall Chinook
  mutate(RST_stream = case_when(
    release_site == 'CLWRSF' & sprrt %in% c('32H','32W','11W') ~ TRUE, # exclude beach sein
    release_site %in% c('IMNAHR','IMNAHW','IMNTRP','JOHNSC','JOHTRP',
                        'LOLOC','LOSTIP','LOSTIR','LSHEEF','MEAD2C','NEWSOC', 
                        'SECTRP') ~ TRUE,
    TRUE ~ FALSE
  )) %>%
  # Assign Release Groups
  mutate(release_groups = case_when(
    # Beach Seining
    release_site == 'CLWR' & tag_coord == 'BDA' & between(release_date, sein_start, sein_end) ~ 'Clearwater Naturals', #13W Beach Sein - NPT', # BA as tag coordinator. Fall Chinook.
    release_site == 'CLWR' & tag_coord == 'WPC' & release_year == 2020 ~ 'Clearwater Naturals', #'13W Beach Sein - USGS', #& release_date == ymd('2020-07-06')  # USGS contribution (worked with NPT on 7/6/20)
    # release_site == 'CLWRSF' & tag_coord == 'BDA' & between(release_date, mdy('07-09-2020'), mdy('07-16-2020')) ~ 'SF Clearwater Beach Sein',# BDA = Billy Arnsberg (SF Beach Seining)
    # RST
    release_site == 'IMNTRP' & between(release_date, imntrp_start, imntrp_end) ~ 'Imnaha River RST', 
    release_site == 'JOHTRP' & between(release_date, johtrp_start, johtrp_end) ~ 'Johnson Creek RST', 
    release_site == 'SECTRP' & between(release_date, sectrp_start, sectrp_end) ~ 'Secesh River RST',
    release_site == 'CLWRSF' & tag_coord == 'NPC' & between(release_date, clwrsf_start, clwrsf_end) ~ 'South Fork Clearwater River RST', # NPC = Nez Perce Clearwater (SF RST)
    release_site == 'LOLOC' & tag_file != 'SCS-2019-211-LC1.XML' & between(release_date, loloc_start, loloc_end) ~ 'Lolo Creek RST', # LC1.XML=11H release
    release_site == 'LOSTIR' & between(release_date, mdy('07/01/2019'), mdy('06/30/2020')) ~ 'Lostine Naturals',
    # FALL CHINOOK
    release_site == 'BCCAP' & tag_file == 'SCS-2020-107-BC1.XML' ~ 'Big Canyon Creek 1st', # 13H
    release_site == 'BCCAP' & tag_file == 'SCS-2020-126-BC2.XML' ~ 'Big Canyon Creek 2nd', # 13H
    release_site == 'CEFLAF' & tag_file == 'SCS-2020-133-CF1.XML' ~ 'Cedar Flats', # 13H
    release_site == 'CJRAP' & tag_file == 'SCS-2020-113-CJ1.XML' ~ "Captain John Rapids 1st", # 13H
    release_site == 'CJRAP' & tag_file == 'SCS-2020-127-CJ2.XML' ~ "Captain John Rapids 2nd", # 13H
    release_site == 'LUGUAF' & tag_file == 'SCS-2020-132-LG1.XML' ~ "Lukes Gulch", # 13H
    release_site == 'NLVP' & tag_file == 'SCS-2020-114-NLV.XML' ~ 'North Lapwai Valley', # 13H
    release_site == 'NPTH' & tag_file == 'SCS-2020-135-OS1.XML' ~ 'NPTH On Station',  # 13H
    release_site == 'PLAP' & tag_file == 'SCS-2020-106-PL1.XML' ~ 'Pittsburg Landing 1st', # 13H
    release_site == 'PLAP' & tag_file == 'SCS-2020-125-PL2.XML' ~ 'Pittsburg Landing 2nd', # 13H
    # SPRING CHINOOK
    release_site == 'KOOS' & tag_file == 'SCS-2019-282-002.XML' ~ '11H KNFH',
    release_site == 'LOLOC' & tag_file == 'SCS-2019-211-LC1.XML' ~ '11H Lolo Creek',
    release_site == 'MEADOC' & tag_file == 'SCS-2019-169-MC1.XML' ~ '11H Meadow Creek (MF Salmon)', # MF Salmon / Meadow Creek
    release_site == 'NEWSOC' & tag_file == 'SCS-2019-211-NC1.XML' ~ '11H Newsome Creek', 
    release_site == 'NPTH' & tag_file %in% c('SCS-2020-070-NP1.XML','SCS-2020-070-NP2.XML') ~ '11H NPTH Spring Chinook',
    release_site %in% c('IMNAHR','IMNAHW') ~ '11H Imnaha',  
    release_site == 'LOSTIP' ~ '11H Lostine',
    release_site == 'JOHNSC' ~ '12H JC',
    # SUMMER STEELHEAD
    release_site == 'CLWRSF' & tag_file %in% c('CBB-2020-008-006.XML','CBB-2020-008-007.XML', 
                                               paste0('BDL-2019-275-W', c(15,16,25,26,35,36,45,46), '.XML')) ~ '32H Red House Hole (SFC)',
    release_site == 'MEAD2C' & tag_file %in% c(paste0('BDL-2019-275-W', c(11:14,21:24,31:34,41:44),'.XML')) ~ '32H Meadow Creek (SFC)', # SF Clearwater / Meadow Creek
    release_site == 'NEWSOC' & tag_file %in% c(paste0('BDL-2019-276-W', c(11,12,21,22,31,32,41,42),'.XML')) ~ '32H Newsome Creek (SFC)',
    release_site == 'LSHEEF' & year(release_date) == 2020 ~ '32H Little Sheep',
    TRUE ~ 'Unassigned')) %>%
  # Groups for plots
  mutate(plot_group = case_when(
    # Fall Chinook
    run == 'Fall' & release_site %in% fchn_clearwater ~ 'Clearwater River',
    run == 'Fall' & release_site %in% fchn_snake ~ 'Snake River',
    # Hatchery (non-fall)
    rear == 'Hatchery' ~ 'Hatchery',
    # Spring/summer Chinook
    species == 'Chinook salmon' & month(release_date) %in% c(1:6) ~ 'Smolt',
    species == 'Chinook salmon' & month(release_date) %in% c(7:8) ~ 'Parr',
    species == 'Chinook salmon' & month(release_date) %in% c(9:12) ~ 'Presmolt',  
    # Summer Steelhead
    species == 'Steelhead' & month(release_date) %in% c(1:6) ~ 'Smolt',
    species == 'Steelhead' & month(release_date) %in% c(7:12) ~ 'Summer/Fall tagged'
  )) %>%
  mutate(release_site_plotnames = case_when(
    release_site == 'IMNTRP' ~ 'Imnaha River RST',
    release_site == 'LSHEEF' ~ 'Little Sheep Acclimation Facility',
    release_site == 'JOHTRP' ~ 'Johnson Creek RST',
    release_site == 'JOHNSC' ~ 'Johnson Creek',
    release_site == 'SECTRP' ~ 'Secesh River RST',
    release_groups == 'Lolo Creek RST' ~ release_groups,
    release_groups == '11H Lolo Creek' ~ 'Lolo Creek at Eldorado Creek Mouth',
    release_site == 'CLWRSF' ~ 'South Fork Clearwater RST',
    release_site == 'NEWSOC' ~ 'Newsome Creek',
    release_site == 'MEAD2C' ~ 'Meadow Creek (SF Clearwater)',
    release_site %in% c('IMNAHW', 'IMNAHR') ~ 'Imnaha River',
    release_site %in% c('LOSTIR', 'LOSTIP') ~ 'Lostine River',
    release_site == 'NPTH' ~ 'NPTH On Station',
    release_site == 'KOOS' ~ 'Kooskia Fish Hatchery',
    release_site == 'MEADOC' ~ 'Meadow Creek (Selway)',
    TRUE ~ paste0('WHAA_', release_site))
  ) %>%
  # FILTERS
  filter(obs_site %in% lgr_sites, # only LGR observation sites
         stage == 'J') %>% # only Juvenile records
  filter(case_when(
    release_site %in% c('IMNTRP','JOHTRP','SECTRP') ~ sprrt %in% c('12W', '32W'),
    release_groups == 'Lolo RST' ~ sprrt %in% c('11W','32W'),
    release_site %in% c('IMNAHW','IMNAHR') ~ sprrt == '11H', # this removes the ODFW ELH 11W's from IMNAHR
    TRUE ~ sprrt == sprrt
  )) %>%
  filter(release_groups != 'Unassigned')

dart_my20$plot_group <- factor(dart_my20$plot_group, levels= c('Parr','Summer/Fall tagged','Presmolt','Smolt','Hatchery',
                                                               'Snake River','Clearwater River'))
  
save(dart_my20, file='./data/arrival/dart_my20.rda')
# load(file='./data/arrival/dart_my20.rda')
