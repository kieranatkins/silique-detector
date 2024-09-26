library(ggplot2)
library(tibble)
library(patchwork)
library(broom)
library(dplyr)
# library(tidyverse)

# Data setup

lab <- function(string){
    paste(string, "- 95th percentile")
}

variables <- c("Length", "Diameter", "Volume", "Area")
variable_names <- c("Length - 95th percentile", "Diameter - 95th percentile", "Volume - 95th percentile", "Area - 95th percentile")
units <- c('mm', 'mm', 'mm³', 'mm²')
data <- tibble(read.csv('p95.csv'))
fs <- list()
for (i in seq_along(variables)){
    unit <- paste0(units[i])
    print(unit)
    print(i)
    v <- variables[i]
    d <- filter(data, variable == v)
    d$Treatment <- as.factor(d$Treatment)
    f <- ggplot(d, aes(x=value, col=Treatment, fill=Treatment)) +  # nolint: infix_spaces_linter.
        geom_step(stat="bin", bins=50, direction = 'mid') +
        geom_histogram(bins=50, alpha=0.3, position = 'identity', colour=NA) +
        # geom_density(alpha=0.2) +
        # stat_summary(fun.data="mean_sdl", geom='pointrange', color='black') +
        facet_wrap(vars(variable), ncol=1, scales='free', labeller=lab) +
        xlab(unit)

    if (i == 1){
        f <- f + theme(ylab(element_blank())) +
            ylab('Count')
    } else {
        f <- f + theme(
            axis.title.y = element_blank(),
            ylab(element_blank()))
    }
    l <- cowplot::get_legend(f)
    fs[[i]] <- f + theme(legend.position = "none")
}
fs[[i+1]] <- l
ggsave(paste0('./p95_distribution.png'), wrap_plots(fs, ncol=5, widths = c(3, 3, 3, 3, 2.0)),  height=2.75, width=12.5)


# data <- tibble(read.csv(paste0(p, '.csv')))
# print(data)
# d$Treatment <- as.factor(d$Treatment)
#
# f <- ggplot(data, aes(x=value, fill=Treatment, color=Treatment))+
#     geom_histogram(alpha=0.2, position='identity') +
#     facet_grid(Treatment ~ variable, scales="free_x")
#
# ggsave(paste0('./test_', p, '_all2.png'), f, height=2, width=4)
