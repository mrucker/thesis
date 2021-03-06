library("ggplot2"); #not strictly necessary here, but we'll use it to make plots in other scripts
library("forcats"); #for fct_recode() and fct_relevel()

figs_path = "C:/Users/Mark/Desktop"

#study results
exp_1 = read.csv("../../../data/studies/_misc/studies1.csv", header = TRUE, sep = ",")
exp_2 = read.csv("../../../data/studies/_misc/studies2.csv", header = TRUE, sep = ",")
exp_3 = read.csv("../../../data/studies/_misc/studies3.csv", header = TRUE, sep = ",")

clean_f_df <- function(a_df) {
    a_df$TWO_R = fct_recode(a_df$TWO_R, LL = "c4op", LH = "b4op", CT = "1", HL = "a3op", HH = "b3op")
    a_df$TWO_R = fct_relevel(a_df$TWO_R, "HH", "HL", "CT", "LH", "LL")

    a_df$ONE_DT = as.POSIXct(a_df$ONE_TS, tz = "", "%Y-%m-%dT%H:%M:%S")

    a_df$Clean_System = as.character(a_df$Clean_System)
    a_df$Clean_System[grepl("android", a_df$Clean_System)] = "android"
    a_df$Clean_System[grepl("ios", a_df$Clean_System)] = "ios"
    a_df$Clean_System[grepl("fedora", a_df$Clean_System)] = "linux"
    a_df$Clean_System[grepl("linux", a_df$Clean_System)] = "linux"
    a_df$Clean_System[grepl("ubuntu", a_df$Clean_System)] = "linux"
    a_df$Clean_System[grepl("windows 8", a_df$Clean_System)] = "windows other"
    a_df$Clean_System[grepl("windows server", a_df$Clean_System)] = "windows other"
    a_df$Clean_System[grepl("windows xp", a_df$Clean_System)] = "windows other"
    #a_df$Clean_System[grepl("ubuntu", a_df$Clean_System)] = "windows other"
    a_df$Clean_System = factor(a_df$Clean_System)

    return(a_df)
}

filter_f_df <- function(a_df) {

    f_df = a_df[
        a_df$First == "yes" &
        a_df$Input == "mouse" &
        a_df$ONE_O >= 430 &
        a_df$TWO_O >= 430 &
        a_df$ONE_F >= 20 &
        a_df$TWO_F >= 20
    ,]

    return(f_df)
}

exp_1 = filter_f_df(clean_f_df(exp_1))
exp_2 = filter_f_df(clean_f_df(exp_2))
exp_3 = filter_f_df(clean_f_df(exp_3))

rm(clean_f_df)
rm(filter_f_df)
#study results

#irl performance
irl = read.csv("../../../data/algorithm/irl.csv", header = TRUE, sep = ",")

clean_irl <- function(irl) {
    irl$algorithm = fct_recode(irl$algorithm, PIRL = "an", KPIRL = "algorithm5", GPIRL = "gpirl")

    return (irl)
}

filter_irl <- function(irl) {
    irl = irl[irl$algorithm != "algorithm9",]

    return (irl)
}

irl = filter_irl(clean_irl(irl))

rm(clean_irl)
rm(filter_irl)
#irl performance

#kla performance
kla = read.csv("../../../data/algorithm/kla.csv", header = TRUE, sep = ",");
#kla performance

#reward functions
R_HH = read.csv("../../../data/algorithm/b3op.csv", header = TRUE, sep = ",")
R_HH$worth_f = factor((R_HH$reward > R_HH$reward[1]) + 0, levels = c(0, 1), labels = c("not worth touching", "worth touching"))

R_LL = read.csv("../../../data/algorithm/c4op.csv", header = TRUE, sep = ",")
R_LL$worth_f = factor((R_LL$reward > R_LL$reward[1]) + 0, levels = c(0, 1), labels = c("not worth touching", "worth touching"))
#reward functions

#utility functions used for making plots
count_title <- function(title, f_df) {
    return(paste(title, " ", "(n=", prettyNum(dim(f_df)[1], big.mark = ","), ")", sep = ""))
}

median_summary <- function(f_df) {
    v1 = data.frame(T = c(f_df$ONE_T, f_df$TWO_T), S = rep(factor(c("Pretest", "Posttest"), levels = c("Pretest", "Posttest")), each = dim(f_df)[1]), I = factor(c(as.character(f_df$Input), as.character(f_df$Input))), R = factor(c(as.character(f_df$TWO_R), as.character(f_df$TWO_R)), levels = c("HH", "HL", "CT", "LH", "LL")));
    v2 = ddply(v1, .(I, S, R), summarize, med = median(T), avg = mean(T), var = var(T));
    return(v2)
}

qq_dataframe_against_reward <- function(theoretical_reward, game, f_df) {

    result = setNames(data.frame(matrix(ncol = 3, nrow = 0)), c("theoretical", "sample", "reward"))
    theoretical = f_df[f_df$TWO_R == theoretical_reward, game]

    for (reward in levels(f_df$TWO_R)) {

        if (reward == theoretical_reward) next

        sample = f_df[f_df$TWO_R == reward, game]

        dd = as.data.frame(qqplot(theoretical, sample, plot.it = FALSE))

        result = rbind(result, data.frame(theoretical = dd$x, sample = dd$y, reward = reward))
    }

    return(result)
}
#utility functions used for making plots

#utility functions for hypothesis testing
treament_cliff <- function(exp, r1, r2) {
    cd = cliff.delta(exp$TWO_T[exp$TWO_R == r1], exp$TWO_T[exp$TWO_R == r2])
    round(c(cd$estimate, cd$conf.int),3)
}

n_mean_median_var <- function(exp, r) {
    round(c(sum(exp$TWO_R == r), mean(exp$TWO_T[exp$TWO_R == r]), median(exp$TWO_T[exp$TWO_R == r]), var(exp$TWO_T[exp$TWO_R == r]) ),3)
}
#utility functions for hypothesis testing