get_marker_names <- function(map, chr, pos){
    marker_names <- c()

    # Terrible runtime
    for (i in seq_along(pos)){
        p <- pos[i]
        c <- toString(chr[i])
        m <- qtl2::find_marker(map, c, p)
        marker_names <- append(marker_names, m)
    }
    return(marker_names)
}