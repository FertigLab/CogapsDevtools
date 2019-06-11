################ HELPER FUNCTIONS ################

# odd function - generate lookup table for [0, inf)
# levels off so return 1 when x > threshold (near 3) - (this will cause issues though since passing 1 into qnorm doesn't work
erf <- function(x) 2 * pnorm(x * sqrt(2)) - 1

# odd function - generate lookup table for [0, 1)
# goes off to infinity as x -> 1
# can fail gibbs when x is too close to 0 or 1 - only need lookup table
# in between
erfinv <- function(x) qnorm((1 + x)/2)/sqrt(2)

erfc <- function(x) 2 * pnorm(x * sqrt(2), lower = FALSE)
erfcinv <- function(x) qnorm(x/2, lower = FALSE)/sqrt(2)

inc_gamma <- function(s, x)
{
    f <- function(t) t^(s - 1) * exp(-t)
    integrate(f, 0, x)$value
}

################ MAIN FUNCTIONS ################

# pdf
gaps_dgamma <- function(x, shape, scale)
{
    (1 / (gamma(shape) * scale ^ shape)) * (x ^ (shape - 1)) * exp(-x / scale)
}

# cdf
gaps_pgamma <- function(x, shape, scale)
{
    #(1 / gamma(shape)) * inc_gamma(shape, x / scale)
    1 - exp(-x / scale) * (1 + x / scale)
}

lookup_size <- 32768
x <- 1:lookup_size
gaps_qgamma_lookup <- qgamma((x-1)/lookup_size, shape=2, scale=1)

# quantile
gaps_qgamma <- function(x, shape, scale)
{
    gaps_qgamma_lookup[floor(x * lookup_size) + 1] * scale 
}

# pdf
gaps_dnorm <- function(x, mean, sd)
{
    exp((x - mean) * (x - mean) / (-2 * sd * sd)) / sqrt(2 * pi * sd * sd)
}

# cdf
erf_lookup <- erf((1:3001 - 1) / 1000)
gaps_pnorm <- function(x, mean, sd)
{
    #0.5 * (1 + erf((x - mean) / (sd * sqrt(2))))
    term <- (x - mean) / (sd * sqrt(2))
    if (term < 0)
    {
        term <- max(term, -3)
        erf <- -erf_lookup[floor(-term * 1000)]
    }
    else
    {
        term <- min(term, 3)
        erf <- erf_lookup[floor(term * 1000)]
    }
    return(0.5 * (1 + erf))
}

# quantile
gaps_qnorm <- function(x, mean, sd)
{
    mean + sd * sqrt(2) * erfinv(2 * x - 1)
}

################ TEST ################

dnorm_diff <- function(x, mean, sd) abs(gaps_dnorm(x, mean, sd) - dnorm(x, mean=mean, sd=sd))
qnorm_diff <- function(x, mean, sd) abs(gaps_qnorm(x, mean, sd) - qnorm(x, mean=mean, sd=sd))

dgamma_diff <- function(x, shape, scale) abs(gaps_dgamma(x, shape, scale) - dgamma(x, shape=shape, scale=scale))
pgamma_diff <- function(x, shape, scale) abs(gaps_pgamma(x, shape, scale) - pgamma(x, shape=shape, scale=scale))
qgamma_diff <- function(x, shape, scale) abs(gaps_qgamma(x, shape, scale) - qgamma(x, shape=shape, scale=scale))

pnorm_diff <- function(x, mean, sd)
{
    truth <- pnorm(x, mean, sd)
    estimate <- gaps_pnorm(x, mean, sd)

    if (estimate < 0.05 | estimate > 0.95)
    {
        return(0)
    }
    return(abs(truth - estimate))
}

test <- function(diff_func, range, a, b)
{
    mx <- 0
    for (r in range)
    {
        if (r == 0 | r == 1)
            next

        diff <- diff_func(r, a, b)
        if (diff > mx)
        {
            mx <- diff
            cat(r, " ", mx, "\n")
        }
    }
    mx
}

tol <- 1e-10

print(test(dnorm_diff, seq(-5, 5, length=10000), 0, 1))
print(test(pnorm_diff, seq(-10, 10, length=10000), 0, 1))
print(test(qnorm_diff, seq(0 + tol, 1 - tol, length=10000), 0, 1))

#print(test(dgamma_diff, seq(0 + tol, 5, length=10000), 1, 1))
#print(test(pgamma_diff, seq(0 + tol, 5, length=10000), 1, 1))
#print(test(qgamma_diff, seq(0 + tol, 1 - tol, length=10000), 2, 1))