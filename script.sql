use dec01assignment; 

SELECT * FROM courses;

SELECT * FROM departments;

SELECT * FROM enrollments; 

SELECT * FROM grades;

SELECT * FROM professors;

SELECT * FROM students;



-- QUERY 1: Professors' ranking

WITH rank_within_department AS (
    SELECT
        c.Course_ID,
        c.Course_Name,
        d.Department_Name,
        CONCAT(p.First_Name, ' ', p.Last_Name) AS Professor_Name,
        COUNT(DISTINCT e.Student_ID) AS Number_of_Students,
        AVG(g.Grade) AS Avg_Grade
    FROM Courses c
    JOIN Enrollments e ON c.Course_ID = e.Course_ID
    JOIN Professors p ON c.Professor_ID = p.Professor_ID
    JOIN Departments d ON p.Department_ID = d.Department_ID
    JOIN Grades g ON c.Course_ID = g.Course_ID
    GROUP BY c.Course_ID, c.Course_Name, d.Department_Name, Professor_Name
)
SELECT Professor_Name, Course_Name, Department_Name, Number_of_Students, Avg_Grade,
RANK() OVER (PARTITION BY Department_Name ORDER BY avg_grade DESC) AS Professor_Rank
FROM rank_within_department
QUALIFY Professor_Rank <= 3 AND Avg_Grade > 75
ORDER BY Professor_Name, Department_Name, Course_Name, Professor_Rank, Avg_Grade DESC;


-- QUERY 2: Students' performance 

WITH student_performance AS (
    SELECT 
        e.Student_ID,
        CONCAT(s.First_Name, ' ', s.Last_Name) AS Student_Name,
        s.Program,
        AVG(g.Grade) AS Avg_Grade,
        MAX(g.Grade) AS Max_Grade,
        COUNT(DISTINCT e.Course_ID) AS Courses_Taken,
        NTILE(4) OVER (PARTITION BY s.Program ORDER BY AVG(g.Grade) DESC) AS Student_Quartile
    FROM Enrollments e
    JOIN Students s ON e.Student_ID = s.Student_ID
    JOIN Grades g ON e.Course_ID = g.Course_ID AND e.Student_ID = g.Student_ID
    --JOIN Courses c ON e.Course_ID = c.Course_ID
    GROUP BY e.Student_ID, s.First_Name, s.Last_Name, s.Program
    QUALIFY Student_Quartile = 1
),
max_grade_courses AS (
    SELECT 
        e.Student_ID,
        c.Course_ID,
        c.Course_Name,
        CONCAT(p.First_Name, ' ', p.Last_Name) AS Professor_Name,
        d.Department_Name,
        g.Grade,
        ROW_NUMBER() OVER (PARTITION BY e.Student_ID ORDER BY g.Grade DESC) AS Grade_Rank
    FROM Enrollments e
    JOIN Grades g ON e.Course_ID = g.Course_ID AND e.Student_ID = g.Student_ID
    JOIN Courses c ON e.Course_ID = c.Course_ID
    JOIN Professors p ON c.Professor_ID = p.Professor_ID
    JOIN Departments d ON p.Department_ID = d.Department_ID
    QUALIFY Grade_Rank = 1
)
SELECT 
    Student_Name,
    Program,
    Avg_Grade,
    Courses_Taken, 
    Max_Grade,
    Course_Name,
    Professor_Name,
    Department_Name
FROM student_performance sp
JOIN max_grade_courses mgc ON sp.Student_ID = mgc.Student_ID
WHERE Avg_Grade > 86 AND Courses_Taken >= 3
ORDER BY Program, Avg_Grade DESC;
