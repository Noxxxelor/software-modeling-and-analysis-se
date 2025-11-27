CREATE DATABASE Telegram;
GO

USE Telegram;
GO


CREATE TABLE [User] (
    UserID       INT PRIMARY KEY IDENTITY(1,1),
    UserName     NVARCHAR(50)  UNIQUE NOT NULL,
    FullName     NVARCHAR(100) NOT NULL,
    Bio          NVARCHAR(MAX),
    PhoneNumber  NVARCHAR(20),
    ProfilePhoto VARBINARY(MAX),
    CreatedAt    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    Email        NVARCHAR(100)  
);
GO


CREATE TABLE Chat (
    ChatID   INT PRIMARY KEY IDENTITY(1,1),
    User1ID  INT NOT NULL REFERENCES [User](UserID),
    User2ID  INT NOT NULL REFERENCES [User](UserID),
    CreatedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    CHECK (User1ID < User2ID),
    UNIQUE (User1ID, User2ID)
);
GO

CREATE TABLE [Group] (
    GroupID      INT PRIMARY KEY IDENTITY(1,1),
    OwnerID      INT NOT NULL REFERENCES [User](UserID),
    [Name]       NVARCHAR(100) NOT NULL,
    [Description] NVARCHAR(500),
    CreatedAt    DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    GroupPhoto   VARBINARY(MAX),
    IsPublic     BIT NOT NULL DEFAULT 1
);
GO


CREATE TABLE GroupMember (
    UserID   INT NOT NULL REFERENCES [User](UserID),
    GroupID  INT NOT NULL REFERENCES [Group](GroupID) ON DELETE CASCADE,
    PRIMARY KEY (UserID, GroupID),
    [Role]   NVARCHAR(20) DEFAULT 'member' CHECK ([Role] IN ('member','admin','owner')),
    JoinedAt DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    IsMuted  BIT NOT NULL DEFAULT 0
);
GO


CREATE TABLE [Message] (
    MessageID           INT PRIMARY KEY IDENTITY(1,1),
    ChatID              INT NULL REFERENCES Chat(ChatID) ON DELETE CASCADE,
    GroupID             INT NULL REFERENCES [Group](GroupID) ON DELETE CASCADE,
    UserID              INT NOT NULL REFERENCES [User](UserID),
    Content             NVARCHAR(MAX),
    CreatedAt           DATETIME2 NOT NULL DEFAULT SYSUTCDATETIME(),
    IsEdited            BIT NOT NULL DEFAULT 0,
    ReplyToMessageID    INT NULL REFERENCES [Message](MessageID),
    ForwardedFromUserID INT NULL REFERENCES [User](UserID),
    CHECK ((ChatID IS NOT NULL AND GroupID IS NULL) OR (ChatID IS NULL AND GroupID IS NOT NULL))
);
GO


CREATE TABLE Attachment (
    AttachmentID INT PRIMARY KEY IDENTITY(1,1),
    MessageID    INT NOT NULL REFERENCES [Message](MessageID) ON DELETE CASCADE,
    FileType     NVARCHAR(50) NOT NULL,
    FileName     NVARCHAR(255),
    FileSize     BIGINT
);
GO
CREATE OR ALTER TRIGGER Tr_Group_AddOwner ON [Group] AFTER INSERT AS
BEGIN
    SET NOCOUNT ON;
    INSERT INTO GroupMember(UserID, GroupID, [Role])
    SELECT OwnerID, GroupID, 'owner' FROM inserted;
END
GO


CREATE OR ALTER FUNCTION Fn_User_GetChatCount(@UserID int) RETURNS int AS
BEGIN
    RETURN (SELECT COUNT(*) FROM Chat WHERE User1ID = @UserID OR User2ID = @UserID);
END
GO

CREATE OR ALTER PROCEDURE Usp_DeleteChat @ChatID int AS
BEGIN
    SET NOCOUNT ON;
    DELETE FROM Chat WHERE ChatID = @ChatID;
END
GO

CREATE OR ALTER TRIGGER TR_Message_CheckContent
ON Message
AFTER INSERT, UPDATE
AS
BEGIN
    SET NOCOUNT ON;

    IF EXISTS (
        SELECT 1
        FROM inserted i
        WHERE i.Content IS NULL                                 
          AND NOT EXISTS (                                      
                SELECT 1 
                FROM Attachment a 
                WHERE a.MessageID = i.MessageID
              )
    )
    BEGIN
        RAISERROR('Съобщение не може да бъде празно — трябва текст или поне едно вложение!', 16, 1);
        ROLLBACK;
    END
END
GO



INSERT INTO [User] (UserName, FullName, Bio, PhoneNumber, Email)
VALUES
('alex',    N'Александър Петров',   N'Обичам програмиране', '+359881000001', 'alex@example.com'),
('maria',   N'Мария Колева',        N'Frontend разработчик', '+359881000002', 'maria@example.com'),
('ivan',    N'Иван Иванов',         N'Data Science ентусиаст', '+359881000003', 'ivan@example.com'),
('elena',   N'Елена Димитрова',     N'UI/UX дизайнер', '+359881000004', 'elena@example.com'),
('petar',   N'Петър Георгиев',      N'Продуктов мениджър', '+359881000005', 'petar@example.com'),
('stella',  N'Стела Николова',      N'Маркетинг специалист', '+359881000006', 'stella@example.com');
GO


INSERT INTO Chat (User1ID, User2ID)
VALUES
(1, 2),
(1, 3),
(2, 4),
(3, 5),
(4, 6);
GO


INSERT INTO [Group] (OwnerID, [Name], [Description], IsPublic)
VALUES
(1, N'Programming BG',  N'Българска общност за програмисти', 1),
(2, N'Design Hub',      N'UI/UX комюнити', 1),
(3, N'Data Science Lab',N'Група за машинно обучение и AI', 1);
GO


INSERT INTO GroupMember (UserID, GroupID, [Role])
VALUES
(2, 1, 'member'),
(3, 1, 'member'),
(4, 1, 'member'),
(1, 2, 'member'),
(4, 2, 'admin'),
(5, 2, 'member'),
(1, 3, 'member'),
(6, 3, 'member');
GO


INSERT INTO [Message] (ChatID, UserID, Content)
VALUES
(1, 1, N'Здрасти, как си?'),
(1, 2, N'Добре съм, ти?'),
(2, 1, N'Готов ли си за проекта?'),
(2, 3, N'Да, започваме!'),
(3, 2, N'Елена, прегледай дизайна.'),
(3, 4, N'Супер, гледам го.'),
(4, 3, N'Петър, провери данните.'),
(4, 5, N'Окей.'),
(5, 4, N'Стела, трябва ми презентация.'),
(5, 6, N'Ще я направя днес.');
GO


INSERT INTO [Message] (GroupID, UserID, Content)
VALUES
(1, 1, N'Добре дошли в Programming BG!'),
(1, 3, N'Някой търси стаж?'),
(1, 2, N'Мога да помогна!'),
(2, 2, N'Готов е новият дизайн.'),
(2, 4, N'Страхотно!'),
(3, 3, N'Утре имаме среща за ML модели.'),
(3, 6, N'Ще присъствам.');
GO


INSERT INTO Attachment (MessageID, FileType, FileName, FileSize)
VALUES
(4,  'image/png', 'project.png', 204800),
(7,  'pdf',       'design.pdf', 509600),
(10, 'docx',      'report.docx', 120000),
(13, 'image/jpg', 'photo.jpg', 340000);
GO



