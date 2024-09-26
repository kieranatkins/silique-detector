library(qtl2ggplot)
library(qtl2helper)
# library(atMAGIC)
library(dplyr)
library(ggplot2)
library(purrr)
library(testit)
library(patchwork)
library(cowplot)
library(tibble)


estimate_heritability <- function(path, herit, metric_order, trait_order){
  herit$Metric_t <- factor(herit$Metric, level=metric_order)
  herit$Phenotype_t <- factor(herit$Phenotype, levels=trait_order)
    p <- ggplot(herit, aes(x=Phenotype_t, y=value, fill=Treatment)) +
      geom_bar(position = 'dodge', stat = 'identity') +
      theme(axis.text.x = element_text(angle = 90)) +
      facet_wrap(vars(Metric_t)) +
      labs(x='Silique trait', y='Heritibility Estimate', fill='Treatment')
      # scale_fill_manual(values = c("slateblue", "violetred"))
    ggsave(path, p, height=5, width=8)
}

genome_scans <- function(filename, cols, name_cols, t1_scan_tbl, t4_scan_tbl, t1_threshold, t4_threshold, max_lod, g){
  t1_scan_tbl <- filter(t1_scan_tbl, pheno %in% cols)
  t4_scan_tbl <- filter(t4_scan_tbl, pheno %in% cols)
  
  custom_x <- list(
        scale_x_continuous(limits = c(0, max(filter(t1_scan_tbl, chrom == 1)$pos))),
        scale_x_continuous(limits = c(0, max(filter(t1_scan_tbl, chrom == 2)$pos))),
        scale_x_continuous(limits = c(0, max(filter(t1_scan_tbl, chrom == 3)$pos))),
        scale_x_continuous(limits = c(0, max(filter(t1_scan_tbl, chrom == 4)$pos))),
        scale_x_continuous(limits = c(0, max(filter(t1_scan_tbl, chrom == 5)$pos)))          
  )
  custom_y <- list()
  for (i in seq_along(cols)){
    col <- cols[i]
    custom_y[[i]] <- scale_y_continuous(limits=c(0, max(max(t1_threshold[, col], t4_threshold[, col]), max(max(filter(t1_scan_tbl, pheno == col)['LOD']), max(filter(t4_scan_tbl, pheno == col)['LOD'])))))
  }

  t1_threshold <- tibble(stack(t1_threshold[, ]))
  t4_threshold <- tibble(stack(t4_threshold[, ]))

  t1_threshold <- filter(t1_threshold, ind %in% cols)
  t4_threshold <- filter(t4_threshold, ind %in% cols)

  t1_scan_tbl <- add_column(t1_scan_tbl, treatment="Isolation")
  t4_scan_tbl <- add_column(t4_scan_tbl, treatment="Groups")
  scan_tbl <- rbind(t1_scan_tbl, t4_scan_tbl)

  t1_threshold <- add_column(t1_threshold, treatment="Isolation")
  t4_threshold <- add_column(t4_threshold, treatment="Groups")
  threshold <- rbind(t1_threshold, t4_threshold)
  threshold$pheno <- threshold$ind

  threshold$pheno_f <- factor(threshold$pheno, levels=cols)
  scan_tbl$pheno_f <- factor(scan_tbl$pheno, levels=cols)
  names(name_cols) <- cols
  print(name_cols)
  lab <- labeller(pheno_f = name_cols)

  s <- ggplot(scan_tbl, aes(x=pos, y=LOD, colour=treatment)) +
    geom_line() +
    geom_hline(data=threshold, aes(yintercept = values, colour=treatment), linetype='dashed') +
    facet_grid(pheno_f ~ chrom, scales="free", labeller=lab) +
    # ylim(0, max(t1_threshold[, col], t4_threshold[, col], t1_scan_max, t4_scan_max)) +
    labs(y='LOD Score', x=NULL,, colour='Treatment') + #, title=name_cols[i]
    scale_fill_manual(values = c("slateblue", "violetred")) +
    # ggtitle(name_cols[i]) +
    theme(axis.text.x=element_blank(),
          axis.ticks.x=element_blank(),
          plot.title=element_text(size=10)) +
    ggh4x::facetted_pos_scales(x = custom_x, y = custom_y)

  genes <- ggplot(g, aes(x=start, y=y)) +
    geom_blank() +
    geom_vline(aes(xintercept=start, color=goi)) +
    facet_grid(vars(set), vars(chr), scales="free_x") +
    theme(axis.ticks.y=element_blank(),
          axis.text.y=element_blank(),
          strip.background.x=element_blank(),
          strip.text.x=element_blank(),
          legend.position = "none") +
    ggh4x::facetted_pos_scales(x = custom_x) +
    labs(x='Chromosome', y=NULL) +
    scale_color_manual(values=c('#b3b3b3', '#b3b3b3'))

  l <- cowplot::get_legend(s)
  p <- cowplot::plot_grid(s + theme(legend.position = "none"), l, genes, NULL, align='v', axis='l', ncol=2, nrow=2, rel_heights = c(8, 1), rel_widths = c(5, 1), labels=c('A', '', 'B', ''))
  ggsave(filename, p, height=8.5, width=10, bg='white')
}

qtl_effect_single_grid  <- function(path, cols, name_cols, qtl_basenames, chrmsm, t1_map, t4_map, t1_aprobs, t4_aprobs, t1, t4, t1_scan_tbl, t4_scan_tbl, t1_peaks, t4_peaks, goi){
  scan_plots <- list()
  effect_plots <- list()
  # goi$start_mb <- apply(X=goi[, 'start'], FUN=(function(x) x/(1000**2)), MARGIN=1)
  print(goi)
  for (i in seq_along(cols)){
    col <- cols[[i]]

    t1_pos <- filter(t1_peaks, (chr == chrmsm) & (lodcolumn == col))
    t4_pos <- filter(t4_peaks, (chr == chrmsm) & (lodcolumn == col))

    t1_scan_col <- filter(t1_scan_tbl, pheno==col)
    t4_scan_col <- filter(t4_scan_tbl, pheno==col)

    t1_scan_col$Treatment <- "Isolation"
    t4_scan_col$Treatment <- "Groups"
    scan_tbl <- rbind(t1_scan_col, t4_scan_col)
    print(scan_tbl)
    scan_tbl <- filter(scan_tbl, (chrom == chrmsm) & (pheno==col))
    scan <- ggplot(scan_tbl, aes(x=pos, y=LOD, colour=Treatment)) +
      geom_line() +
      ylim(0, max(scan_tbl$LOD)) +
      geom_vline(data = goi, aes(xintercept=start), color='grey45', linetype='solid') +
      geom_text(data = goi, size=3, hjust=1.2, y=1.0, aes(x=start, label=gene_name), color='black') +
      facet_grid(pheno ~ chrom, scales="free", labeller=labeller(pheno=as_labeller(name_cols))) +
      labs(y='LOD Score', x='Position (Mb)', colour='Treatment')

    l <- cowplot::get_legend(scan)
    t1_pr <- qtl2::pull_genoprobpos(t1_aprobs, t1_map, chrmsm, t1_pos$pos_p)
    t4_pr <- qtl2::pull_genoprobpos(t4_aprobs, t4_map, chrmsm, t4_pos$pos_p)

    # t1_pr <- qtl2::pull_genoprobpos(t1_aprobs, t1_map, chrmsm, goi$start[[1]])
    # t4_pr <- qtl2::pull_genoprobpos(t4_aprobs, t4_map, chrmsm, goi$start[[1]])

    t1_f1 <- qtl2::fit1(t1_pr, t1$pheno[, col])
    t4_f1 <- qtl2::fit1(t4_pr, t4$pheno[, col])

    t1_coef <- tibble(stack(t1_f1$coef))  
    t1_coef <- filter(t1_coef, ind != "intercept")
    t1_coef$Treatment <- "Isolation"
    t4_coef <- tibble(stack(t4_f1$coef))
    t4_coef <- filter(t4_coef, ind != "intercept") 
    t4_coef$Treatment <- "Groups"
    coef <- rbind(t1_coef, t4_coef)
    coef$qtl <- paste0(qtl_basenames[[i]], "1")

    max_val <- max(abs(min(coef$values)), max(coef$values))
    effect <- ggplot(coef, aes(x=ind, y=values)) +
      geom_bar(stat="identity", aes(fill=Treatment)) +
      facet_grid(vars(Treatment), vars(qtl)) +
      labs(y='Coefficient', x='Founder') +
      theme(legend.position = "none",
            strip.background.y = element_blank(),
            strip.text.y = element_blank(),
            axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
      scale_y_continuous(limits=c(0-max_val, max_val), labels = scales::label_number(accuracy = 0.01))
    if (i == 1){
      scan <- scan + theme(
        axis.title.x = element_blank()
      )
      effect <- effect + theme(
        axis.title.x = element_blank()
      )
    }
    scan_plots[[i]] <- scan + theme(legend.position = "none")
    effect_plots[[i]] <- effect
  }
  plots <- c(scan_plots, effect_plots, list(l))
  # plots <- c(scan_plots[1], effect_plots[1], scan_plots[2], effect_plots[2], list(l))
  plot <- plot_grid(plotlist=plots, ncol=3, nrow=2,align='v', axis='l', byrow = FALSE, rel_heights=c(1, 1.05), rel_widths=c(1, 1, 0.5), labels=c('A', '', '', 'B') )
  ggsave(path, plot, width=8, height=5, bg='white')
}

qtl_effect_single  <- function(path, col, name_cols, qtl_basename, chrmsm, t1_map, t4_map, t1_aprobs, t4_aprobs, t1, t4, t1_scan_tbl, t4_scan_tbl, t1_peaks, t4_peaks){
  t1_pos <- filter(t1_peaks, (chr == chrmsm) & (lodcolumn == col))
  t4_pos <- filter(t4_peaks, (chr == chrmsm) & (lodcolumn == col))
  t1_pos$pos_mb <- apply(X=t1_pos[, 'pos_p'], FUN=(function(x) x/(1000**2)), MARGIN=1)
  t4_pos$pos_mb <- apply(X=t4_pos[, 'pos_p'], FUN=(function(x) x/(1000**2)), MARGIN=1)

  qtl_col <- NULL
  for (i in seq_len(nrow(t4_pos))){
    qtl_name <- paste0(qtl_basename, i)
    qtl_col <- c(qtl_col, qtl_name)
  }
  t4_pos <- mutate(t4_pos, qtl=qtl_col)
  t1_scan_col <- filter(t1_scan_tbl, pheno==col)
  t4_scan_col <- filter(t4_scan_tbl, pheno==col)

  t1_scan_col$Treatment <- "Isolation"
  t4_scan_col$Treatment <- "Groups"
  scan_tbl <- rbind(t1_scan_col, t4_scan_col)
  scan_tbl <- filter(scan_tbl, (chrom == chrmsm) & (pheno==col))
  scan <- ggplot(scan_tbl, aes(x=pos, y=LOD, colour=Treatment)) +
    geom_line() +
    geom_vline(data = t4_pos, aes(xintercept=pos_mb), color='black', linetype='dotted') +
    geom_text(data = t4_pos, size=3, hjust=1.1, y=3.0, aes(x=pos_mb, label=qtl), color='black') +

    facet_grid(pheno ~ chrom, scales="free", labeller=labeller(pheno=as_labeller(name_cols))) +
    labs(y='LOD Score', x='Position (Mb)', colour='Treatment')

  l <- cowplot::get_legend(scan)

  effects <- list()
  for (i in seq_len(nrow(t4_pos))){
    pos <- t4_pos$pos_p[[i]]
    t4_pr <- qtl2::pull_genoprobpos(t4_aprobs, t4_map, chrmsm, pos)

    t4_f1 <- qtl2::fit1(t4_pr, t4$pheno[, col])

    t4_coef <- tibble(stack(t4_f1$coef))
    t4_coef <- filter(t4_coef, ind != "intercept") 
    t4_coef$Treatment <- "Groups"
    t4_coef$qtl <- t4_pos$qtl[[i]]

    max_val <- max(abs(min(t4_coef$values)), max(t4_coef$values))
    effect <- ggplot(t4_coef, aes(x=ind, y=values)) +
      geom_bar(stat="identity", aes(fill=Treatment)) +
      facet_grid(.~ qtl) +
      labs(y='Coefficient', x='Founder') +
      theme(legend.position = "none",
            axis.text.x = element_text(angle = 90, vjust = 0.5, hjust=1)) +
      scale_y_continuous(limits=c(0-max_val, max_val), labels = scales::label_number(accuracy = 0.01))
    if (i != 1){
      effect <- effect + theme(axis.title.y=element_blank())
    }
    effects[[i]] <- effect
  }
  plots <- c(list(scan + theme(legend.position = "none")), effects, list(l))
  plot <- plot_grid(plotlist=plots, ncol=4, nrow=1, align='v', axis='l', rel_widths=c(1, 1, 1, 0.6))
  ggsave(path, plot, width=11, height=3, bg='white')
}
