function get_scores(student_num, mu::Float64, sigma2::Float64, sigma2_error::Float64)
    #生徒の成績が平均mu, 分散sigma2の正規分布に従うと仮定.
    #成績には分散sigma2_errorの誤差が混入すると仮定
    return mu + sqrt(sigma2 + sigma2_error) * randn(student_num)
end

function get_scores(student_num, distribution, error_distribution)
    #生徒の成績が与えられた分布に従うと仮定.
    #成績には与えられた分布の誤差が混入すると仮定
    return [rand(distribution) + rand(error_distribution) for i in 1:student_num]
end

using PyPlot
plot(get_scores(500, 50, 20, 4))
