function get_scores(student_num, mu, sigma2, sigma2_error)
    #生徒の成績が平均mu, 分散sigma2の正規分布に従うと仮定.
    #成績には分散sigma2_errorの誤差が混入すると仮定
    scores = mu + sqrt(sigma2 + sigma2_error) * randn(student_num)
    return scores
end
"
using PyPlot
plot(get_scores(500, 50, 20, 4))
"
