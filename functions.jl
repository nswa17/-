function get_score(mu::Float64, sigma2::Float64, sigma2_error::Float64)
    #生徒の成績が平均mu, 分散sigma2の正規分布に従うと仮定.
    #成績には分散sigma2_errorの誤差が混入すると仮定
    return mu + sqrt(sigma2 + sigma2_error) * randn()
end

function get_score(distribution, error_distribution)
    #生徒の成績が与えられた分布に従うと仮定.
    #成績には与えられた分布の誤差が混入すると仮定
    return rand(distribution) + rand(error_distribution) for i in 1:student_num
end

type Student
    score::Float64
    unobservable_score_science::Float64
    unobservable_score_liberal_arts::Float64
end

function generate_students(students_num, distribution, error_distribution; indep = false)
    Students_list = fill(Student(), students_num)
    for i in 1:students_num
        if indep####Studentsの成績と観測不能な理系・文系への適正が全て独立な場合
            Students_list[i].score = get_score(distribution, error_distribution)
            Students_list[i].unobservable_score_science = get_score(distribution, error_distribution)
            Students_list[i].unobservable_score_science = get_score(distribution, error_distribution)
        else
            Students_list[i].score = get_score(distribution, error_distribution)
            Students_list[i].unobservable_score_science = Students_list[i].score(1 + 0.2*(rand() + 0.5))
            Students_list[i].unobservable_score_science = Students_list[i].score(1 + 0.2*(rand() + 0.5))
        end
    end
end

function generate_students(students_num, mu, sigma2, sigma2_error; indep=false)
    Students_list = fill(Student(), students_num)
    for i in 1:students_num####Studentsの成績と観測不能な理系・文系への適正が全て独立な場合
        if indep
            Students_list[i].score = get_score(mu, sigma2, sigma2_error)
            Students_list[i].unobservable_score_science = get_score(mu, sigma2, sigma2_error)
            Students_list[i].unobservable_score_science = get_score(mu, sigma2, sigma2_error)
        else
            Students_list[i].score = get_score(mu, sigma2, sigma2_error)
            Students_list[i].unobservable_score_science = Students_list[i].score(1 + 0.2*(rand() + 0.5))
            Students_list[i].unobservable_score_science = Students_list[i].score(1 + 0.2*(rand() + 0.5))
        end
    end
end

function get_sorted_students(students, alpha, beta)#alpha...学部の文系度合い, 学部の理系度合い（それぞれ[0, 1])の値を取る
    sort!(students, x->x.score+alpha*x.unobservable_score_science+beta*x.unobservable_score_liberal_arts)
end
