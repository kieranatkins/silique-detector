# library(qtl2)
library(qtl2ggplot)
library(qtl2helper)
library(dplyr)
library(ggplot2)
library(purrr)
library(testit)
library(patchwork)
library(cowplot)
library(tibble)

source('qtl_graphs_treatments.r')
source('qtl_utils.r')

# Load the data to the environment
kover2009 <- atMAGIC::kover2009

# pheno <- read.csv("phenotype_out_7873621_prepared.csv")
pheno <- read.csv("./data/phenotype_out_7934899_prepared.csv")
genes <- tibble(read.csv("./out/genes/filtered_genes.csv")[, c("start", "end", "chr", "goi", "gene_name", "set")])

cols <- c(
  'length_p95',
  'length_mean',
  'length_rsd',
  'diameter_p95',
  'diameter_mean',
  'diameter_rsd',
  'volume_p95',
  'volume_mean',
  'volume_rsd',
  'area_p95',
  'area_mean',
  'area_rsd'
)

####### t4 ##########
print("Treatment 4")
print(format(Sys.time(), "%H:%M:%S"))
time <- proc.time()
data <- filter(pheno, treatment == 4)
t4_batch <- data$batch
data <- data[,names(data) %in% c("SUBJECT.NAME", cols)]

t4 <- qtl2helper::add_pheno(kover2009, data, idcol = "SUBJECT.NAME")
# t4$covar$batch <- t4_batch
names(t4_batch) <- data$SUBJECT.NAME

t4_probs <- qtl2::calc_genoprob(t4, error_prob = 0.002)
t4_aprobs <- qtl2::genoprob_to_alleleprob(t4_probs)
t4_kinship <- qtl2::calc_kinship(t4_probs, 'loco')
t4_akinship <- qtl2::calc_kinship(t4_aprobs, 'loco')
t4_scan <- qtl2::scan1(t4_probs, t4$pheno, t4_kinship, t4_batch)
t4_ascan <- qtl2::scan1(t4_aprobs, t4$pheno, t4_akinship, t4_batch)
t4_maxlod <- qtl2::maxlod(t4_scan)
t4_perm <- qtl2::scan1perm(t4_probs, t4$pheno, n_perm = 1000, t4_kinship, t4_batch, cores=0)

t4_threshold <- summary(t4_perm, alpha=0.05)  # default alpha is 0.05
t4_peaks <- qtl2::find_peaks(t4_scan, t4$gmap, prob=0.95, expand2markers=FALSE, threshold=t4_threshold, peakdrop=4)
t4_p_peaks <- qtl2::find_peaks(t4_scan, t4$pmap, prob=0.95, expand2markers=FALSE, threshold=t4_threshold, peakdrop=4)

t4_peaks <- rename(t4_peaks, pos_g=pos)
t4_peaks <- rename(t4_peaks, ci_lo_g=ci_lo)
t4_peaks <- rename(t4_peaks, ci_hi_g=ci_hi)
t4_peaks$pos_p <- t4_p_peaks$pos
t4_peaks$ci_lo_p <- t4_p_peaks$ci_lo
t4_peaks$ci_hi_p <- t4_p_peaks$ci_hi
mn <- get_marker_names(t4$gmap, t4_peaks$chr, t4_peaks$pos_g)
t4_peaks$marker_name <- mn
print((proc.time()-time)["elapsed"])

########## t1 ##############
print("Treatment 1")
print(format(Sys.time(), "%H:%M:%S"))
time <- proc.time()

data <- filter(pheno, treatment == 1)
t1_batch <- data$batch
data <- data[, names(data) %in% c("SUBJECT.NAME", cols)]

# add batch as covar
t1 <- qtl2helper::add_pheno(kover2009, data, idcol = "SUBJECT.NAME", retain_all = TRUE)
# t1$covar$batch <- t1_batch
names(t1_batch) <- data$SUBJECT.NAME

t1_probs <- qtl2::calc_genoprob(t1, error_prob = 0.002)
t1_aprobs <- qtl2::genoprob_to_alleleprob(t1_probs)
t1_kinship <- qtl2::calc_kinship(t1_probs, 'loco')
t1_akinship <- qtl2::calc_kinship(t1_aprobs, 'loco')
t1_scan <- qtl2::scan1(t1_probs, t1$pheno, t1_kinship, t1_batch)
t1_ascan <- qtl2::scan1(t1_aprobs, t1$pheno, t1_akinship, t1_batch)
t1_maxlod <- qtl2::maxlod(t1_scan)
t1_perm <- qtl2::scan1perm(t1_probs, t1$pheno, n_perm = 1000, t1_kinship, t1_batch, cores=0)
t1_threshold <- summary(t1_perm, alpha=0.05)  # default alpha is 0.05

t1_peaks <- qtl2::find_peaks(t1_scan, t1$gmap, prob=0.95, expand2markers=FALSE, threshold=t1_threshold, peakdrop=4)
t1_p_peaks <- qtl2::find_peaks(t1_scan, t1$pmap, prob=0.95, expand2markers=FALSE, threshold=t1_threshold, peakdrop=4)

t1_peaks <- rename(t1_peaks, pos_g=pos)
t1_peaks <- rename(t1_peaks, ci_lo_g=ci_lo)
t1_peaks <- rename(t1_peaks, ci_hi_g=ci_hi)
t1_peaks$pos_p <- t1_p_peaks$pos
t1_peaks$ci_lo_p <- t1_p_peaks$ci_lo
t1_peaks$ci_hi_p <- t1_p_peaks$ci_hi
mn <- get_marker_names(t1$gmap, t1_peaks$chr, t1_peaks$pos_g)
t1_peaks$marker_name <- mn

t1_peaks$treatment <- 1
t4_peaks$treatment <- 4
peaks <- rbind(t1_peaks, t4_peaks)

write.csv(peaks, './out/qtl/peaks.csv')
print((proc.time()-time)["elapsed"])

# Prepare data in tibble format for ggplot graphing
t1_scan_tbl <- tidy(t1_scan, t1$pmap)
t1_scan_tbl$pos_raw <- t1_scan_tbl$pos
t1_scan_tbl$pos <- apply(X=t1_scan_tbl[, 'pos_raw'], FUN=(function(x) x/(1000**2)), MARGIN=1)

t4_scan_tbl <- tidy(t4_scan, t4$pmap)
t4_scan_tbl$pos_raw <- t4_scan_tbl$pos
t4_scan_tbl$pos <- apply(X=t4_scan_tbl[, 'pos_raw'], FUN=(function(x) x/(1000**2)), MARGIN=1)

lod <- max(c(t1_maxlod, t4_maxlod))

t1_ascan_tbl <- tidy(t1_ascan, t1$pmap)
t4_ascan_tbl <- tidy(t4_ascan, t4$pmap)

t1_ascan_tbl$pos_raw <- t1_ascan_tbl$pos
t1_ascan_tbl$pos <- apply(X=t1_ascan_tbl[, 'pos_raw'], FUN=(function(x) x/(1000**2)), MARGIN=1)
t4_ascan_tbl$pos_raw <- t4_ascan_tbl$pos
t4_ascan_tbl$pos <- apply(X=t4_ascan_tbl[, 'pos_raw'], FUN=(function(x) x/(1000**2)), MARGIN=1)

genes$start <- genes$start / (1000**2)
genes$y <- 1

###### QTL EFFECTS #######

name_cols <- c(length_p95="Length - 95th percentile", diameter_p95="Diameter - 95th percentile")
qtl_basenames <- c("SL2-", "SD2-")
p <- paste0("./out/qtl/erecta.png")
goi <- filter(genes, goi=="True")
qtl_effect_single_grid(p, c('length_p95', 'diameter_p95'), name_cols, qtl_basenames, "2", t1$pmap, t4$pmap, t1_aprobs, t4_aprobs, t1, t4, t1_scan_tbl, t4_scan_tbl, tibble(t1_peaks), tibble(t4_peaks), goi)

name_cols <- c(volume_p95="Volume - 95th percentile")
qtl_basename <- "SV1-"
p <- paste0("./out/qtl/other_qtl.png")
goi <- filter(genes, goi=="True")
qtl_effect_single(p, 'volume_p95', name_cols, qtl_basename, "1", t1$pmap, t4$pmap, t1_aprobs, t4_aprobs, t1, t4, t1_scan_tbl, t4_scan_tbl, tibble(t1_peaks), tibble(t4_peaks))

##### SCANS ######


t4_scan_tbl <- tidy(t4_scan, t4$pmap)
t4_scan_tbl$pos_raw <- t4_scan_tbl$pos
t4_scan_tbl$pos <- apply(X=t4_scan_tbl[, 'pos_raw'], FUN=(function(x) x/(1000**2)), MARGIN=1)
t4_threshold <- summary(t4_perm, alpha=0.05)  # default alpha is 0.05
t1_threshold <- summary(t1_perm, alpha=0.05)  # default alpha is 0.05

p <- paste0('./out/qtl/scans_p95.png')
sub_cols <- c("length_p95", "diameter_p95", "volume_p95", "area_p95")
name_cols <- c('Length - 95th percentile', 'Diameter - 95th percentile', 'Volume - 95th percentile', 'Area - 95th percentile')
genome_scans(p, sub_cols, name_cols, t1_scan_tbl, t4_scan_tbl, t1_threshold, t4_threshold, lod, genes)

p <- paste0('./out/qtl/scans_mean.png')
sub_cols <- c("length_mean", "diameter_mean", "volume_mean", "area_mean")
name_cols <- c('Length - Mean', 'Diameter - Mean', 'Volume - Mean', 'Area - Mean')
genome_scans(p, sub_cols, name_cols, t1_scan_tbl, t4_scan_tbl, t1_threshold, t4_threshold, lod, genes)

p <- paste0('./out/qtl/scans_rsd.png')
sub_cols <- c("length_rsd", "diameter_rsd", "volume_rsd", "area_rsd")
name_cols <- c('Length - RSD', 'Diameter - RSD', 'Volume - RSD', 'Area - RSD')
genome_scans(p, sub_cols, name_cols, t1_scan_tbl, t4_scan_tbl, t1_threshold, t4_threshold, lod, genes)

#### HERITABILITY ####
order_mean <- c('length_mean', 'diameter_mean', 'volume_mean', 'area_mean')
order_u10 <- c('length_p95', 'diameter_p95', 'volume_p95', 'area_p95')
order_rsd <- c('length_rsd', 'diameter_rsd', 'volume_rsd', 'area_rsd')
order <- c(order_u10, order_mean, order_rsd)

h_t1 <- qtl2::est_herit(t1$pheno, qtl2::calc_kinship(t1_probs), addcovar=t1_batch)
h_t4 <- qtl2::est_herit(t4$pheno, qtl2::calc_kinship(t4_probs), addcovar=t4_batch)
h_t1_t <- tibble(h_t1)
h_t4_t <- tibble(h_t4)
h_t1_t <- rename(h_t1_t, value=h_t1)
h_t4_t <- rename(h_t4_t, value=h_t4)
h_t1_t$Phenotype <- names(h_t1)
h_t4_t$Phenotype <- names(h_t4)
h_t1_t$Treatment <- "Isolation"
h_t4_t$Treatment <- "Groups"
h <- rbind(h_t1_t, h_t4_t)
h_mean <- filter(h, Phenotype=='length_mean' | Phenotype=='diameter_mean' | Phenotype=='volume_mean' | Phenotype=='area_mean')
h_u10 <- filter(h, Phenotype=='length_p95' | Phenotype=='diameter_p95' | Phenotype=='volume_p95' | Phenotype=='area_p95')
h_rsd <- filter(h, Phenotype=='length_rsd' | Phenotype=='diameter_rsd' | Phenotype=='volume_rsd' | Phenotype=='area_rsd')

h_mean <- mutate(h_mean, Phenotype=case_when(Phenotype == 'length_mean' ~ 'Length', 
                                             Phenotype == 'diameter_mean' ~ 'Diameter',
                                             Phenotype == 'volume_mean' ~ 'Volume',
                                             Phenotype == 'area_mean' ~ 'Area' ))

h_u10 <- mutate(h_u10, Phenotype=case_when(Phenotype == 'length_p95' ~ 'Length',
                                           Phenotype == 'diameter_p95' ~ 'Diameter',
                                           Phenotype == 'volume_p95' ~ 'Volume',
                                           Phenotype == 'area_p95' ~ 'Area' ))

h_rsd <- mutate(h_rsd, Phenotype=case_when(Phenotype == 'length_rsd' ~ 'Length', 
                                           Phenotype == 'diameter_rsd' ~ 'Diameter',
                                           Phenotype == 'volume_rsd' ~ 'Volume',
                                           Phenotype == 'area_rsd' ~ 'Area' ))

h_mean$Metric <- "Mean"
h_u10$Metric <- "95th percentile"
h_rsd$Metric <- "RSD"

h <- rbind(h_mean, h_u10, h_rsd)

metric_order <- c('Mean', '95th percentile','RSD')
trait_order <- c("Length", "Diameter", "Volume", "Area")
estimate_heritability("./out/herit.png", h, metric_order, trait_order)


