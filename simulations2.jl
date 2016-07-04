include("functions.jl")

faculty_num = 3
student_num = 20
mu = 0.5
sigma2 = 0.2
sigma2_error = 0.05

faculties_list = [Faculty(i, Array(Int, student_num+1), rand(), rand(), 5, [i]) for i in 1:faculty_num]
students_list = generate_students(student_num, mu, sigma2, sigma2_error, faculty_num)

set_prefs_faculties(faculties_list, students_list)
set_prefs_students(students_list, faculties_list)
#println(faculties_list)

s_prefs = generate_prefs(students_list)
f_prefs = generate_prefs(faculties_list)
caps = generate_caps(faculties_list)

#println(s_prefs)
#println(f_prefs)

s_matched, f_matched, indptr = DA.call_match(s_prefs, f_prefs, caps)

println(s_matched, f_matched)
println(evaluate_matched(s_matched, s_prefs))
println(evaluate_matched2(s_matched, s_prefs))
println(evaluate_matched3(s_matched, s_prefs))
#sorted_students_list = get_sorted_students_list(students_list, faculties_list)
#println(sorted_students_list)
