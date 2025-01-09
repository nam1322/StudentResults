/*
Triggers using High level language extension such as Display
student result and invalid condition.
Objective: Implement triggers in a database to automate actions in response to specific events,
such as data modifications. This assignment focuses on using triggers for tasks like displaying
student results and handling invalid conditions.
Scenario:You will create a database schema that includes tables for Students, Results, and Subjects.
Triggers will be set up to automatically respond to changes in these tables, such as calculating
and displaying final results or checking for invalid data entries.
*/
CREATE DATABASE SchoolDB1;
USE SchoolDB1;

CREATE TABLE Students(
StudentID INT PRIMARY KEY AUTO_INCREMENT,
FirstName VARCHAR(50),
LastName VARCHAR(50),
DateOfBirth DATE);

INSERT INTO Students(FirstName,LastName,DateOfBirth) VALUES
('T','Swift','1989-12-13'),
('Jane','Austen','1999-05-22');
SELECT*FROM Students;

CREATE TABLE Subjects(
SubjectID INT PRIMARY KEY AUTO_INCREMENT,
SubjectName VARCHAR(100),
MaximumMarks INT);

INSERT INTO Subjects(SubjectName,MaximumMarks) VALUES
('Math',100),
('Phy',100);
SELECT*FROM Subjects;

CREATE TABLE Results(
ResultID INT PRIMARY KEY AUTO_INCREMENT,
StudentID INT,
SubjectID INT,
MarksObtained INT,
FOREIGN KEY (StudentID) REFERENCES Students(StudentID) ON DELETE CASCADE,
FOREIGN KEY (SubjectID) REFERENCES Subjects(SubjectID) ON DELETE CASCADE);

INSERT INTO Results(StudentID,SubjectID,MarksObtained) VALUES
(1,1,85),(1,2,75), 
(2,1,65),(2,2,80); 
SELECT*FROM Results;

CREATE TABLE StudentResults(
StudentID INT PRIMARY KEY,
TotalMarks INT,
Status VARCHAR(10),
FOREIGN KEY (StudentID) REFERENCES Students(StudentID) ON DELETE CASCADE);

DELIMITER // 
CREATE TRIGGER be_result_insert 
BEFORE INSERT ON Results FOR EACH ROW 
BEGIN
DECLARE max_marks INT; 
SELECT MaximumMarks INTO max_marks FROM Subjects 
WHERE SubjectID = NEW.SubjectID; 
IF NEW.MarksObtained > max_marks OR NEW.MarksObtained <0 THEN 
 SIGNAL SQLSTATE '99999' 
 SET MESSAGE_TEXT = 'Marks obtained cannot exceed maximum marks for the subject.'; 
END IF; 
END//
DELIMITER ;

DELIMITER // 
CREATE TRIGGER be_result_update
BEFORE UPDATE ON Results FOR EACH ROW 
BEGIN
DECLARE max_marks INT; 
SELECT MaximumMarks INTO max_marks FROM Subjects 
WHERE SubjectID = NEW.SubjectID; 
IF NEW.MarksObtained > max_marks OR NEW.MarksObtained <0 THEN 
SIGNAL SQLSTATE '99999' 
SET MESSAGE_TEXT = 'Marks obtained cannot exceed maximum marks for the subject.'; 
END IF; 
END//
DELIMITER ; 

UPDATE Results 
SET MarksObtained = '101' WHERE ResultID = '1';

DELIMITER // 
CREATE PROCEDURE total_score() 
BEGIN
DECLARE done INT DEFAULT 0; 
DECLARE student_id INT; 
DECLARE totalmarks INT; 
DECLARE status VARCHAR(10); 
DECLARE cur CURSOR FOR SELECT DISTINCT StudentID FROM Results; 
DECLARE CONTINUE HANDLER FOR NOT FOUND SET done=1; 
OPEN cur; 
read_loop:LOOP 
 FETCH cur INTO student_id; 
 IF done THEN 
  LEAVE read_loop; 
 END IF; 
 SELECT SUM(MarksObtained) INTO totalmarks FROM Results 
 WHERE StudentID = student_id; 
 IF totalmarks>=160 THEN
  SET STATUS = 'Passed'; 
 ELSE
  SET STATUS = 'Failed'; 
 END IF; 
 INSERT INTO StudentResults(StudentId,TotalMarks,Status) 
 VALUES(student_id,totalmarks,status) 
 ON DUPLICATE KEY UPDATE
 TotalMarks = VALUES(totalmarks), 
 Status = VALUES(status); 
END LOOP; 
CLOSE cur; 
END// 
DELIMITER ;

DELIMITER // 
CREATE TRIGGER after_result_update 
AFTER UPDATE ON Results 
FOR EACH ROW
BEGIN 
CALL total_score(); 
END// 
DELIMITER ;

UPDATE Results 
SET MarksObtained = '86' WHERE ResultID = '3'; 
SELECT * FROM StudentResults;