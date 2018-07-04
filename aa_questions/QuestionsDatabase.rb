require 'sqlite3'
require 'singleton'

class QuestionsDatabase < SQLite3::Database
  include Singleton
  
  def initialize
    super('aa_questions.db')
    self.type_translation = true
    self.results_as_hash = true
  end
end

class User
  attr_accessor :fname, :lname
  
  def self.find_by_id(id)
    user = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        users
      WHERE
        id = ?
    SQL
    
    return nil if user.empty?
    
    User.new(user.first)
  end
  
  def self.find_by_name(fname, lname)
    user = QuestionsDatabase.instance.execute(<<-SQL, fname, lname)
      SELECT
        *
      FROM
        users
      WHERE
        fname = ? AND lname = ?
    SQL
    
    return nil if user.empty?
    
    user.map { |u| User.new(u) }
  end 
  
  def initialize(options)
    @id = options['id']
    @fname = options['fname']
    @lname = options['lname']
  end
  
  def create
    raise "#{self} already in database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @fname, @lname)
      INSERT INTO
        users (fname, lname)
      VALUES
        (?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end
  
  def followed_questions
    QuestionFollows.followed_questions_for_user_id(@id)
  end
  
  def authored_questions
    raise "Not yet created" unless @id
    Question.find_by_author(@id)
  end
  
  def authored_replies
    raise "Not yet created" unless @id
    Reply.find_by_user_id(@id)
  end
  
  def liked_questions
    QuestionLikes.liked_questions_for_user_id(@id)
  end 
end


class Question
  attr_accessor :title, :body, :author_id
    
    def self.find_by_author(author_id)
      quest = QuestionsDatabase.instance.execute(<<-SQL, author_id)
        SELECT
          *
        FROM
          questions
        WHERE
          author_id = ?
      SQL
      
      return nil if quest.empty?
      
      quest.map { |q| Question.new(q) }
    end 
    
    def self.find_by_question(id)
      quest = QuestionsDatabase.instance.execute(<<-SQL, id)
        SELECT
          *
        FROM
          questions
        WHERE
          id = ?
      SQL
      
      return nil if quest.empty?
      
      quest.map { |q| Question.new(q) }
    end 
    
    def self.most_followed(n)
      QuestionFollow.most_followed_questions(n)
    end
    
    def initialize(options)
      @id = options['id']
      @title = options['title']
      @body = options['body']
      @author_id = options['author_id']
    end 
    
    def create
      raise "#{self} already in database" if @id
      QuestionsDatabase.instance.execute(<<-SQL, @title, @body, @author_id)
        INSERT INTO
          questions (title, body, author_id)
        VALUES
          (?, ?, ?)
      SQL
      @id = QuestionsDatabase.instance.last_insert_row_id
    end
    
    def followers
      QuestionFollows.followers_for_question_id(@id)
    end 
    
    def author
      User.find_by_id(@author_id)
    end
    
    def replies
      raise "Not yet created" unless @id
      Reply.find_by_question_id(@id)
    end
    
    def likers
      raise "Not yet created" unless @id
      QuestionLikes.likers_for_question_id(@id)
    end 
    
    def num_likes
      QuestionLikes.likers_for_question_id(@id)
      
    end 
end

class QuestionLikes
  attr_accessor :question_like, :user_id
  
  def self.likers_for_question_id(question_id)
    likers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        users
      WHERE
        users.id  IN (
          SELECT
            user_id
          FROM
            question_likes
          WHERE
            question_like = ?
        )
    SQL
    
    return nil if likers.empty? 
    likers.map { |l| User.new(l) }
  end
  
  def self.liked_questions_for_user_id(user_id)
    quests = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        questions
      WHERE
        questions.id  IN (
          SELECT
            question_like
          FROM
            question_likes
          WHERE
            user_id = ?
        )
    SQL
    
    return nil if quests.empty? 
    quests.map { |l| Question.new(l) }
  end
  
end

class QuestionFollows
  attr_accessor :user_id, :question_id
  
  def self.followers_for_question_id(question_id)
    followers = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        fname, lname
      FROM
        questions
      JOIN
        users ON users.id = questions.author_id
      WHERE
        questions.id = ?
    SQL
    
    return nil if followers.empty?
    
    followers.map { |u| User.new(u) }
  end 

  def self.followed_questions_for_user_id(author_id)
    followed_qs = QuestionsDatabase.instance.execute(<<-SQL, author_id)
      SELECT
        *
      FROM 
        questions
      JOIN
        users ON questions.author_id = users.id
      WHERE
        author_id = ?
    SQL
    
    return nil if followed_qs.empty? 
    
    followed_qs.map { |q| Question.new(q) }
  end 
  
  def self.most_followed_questions(n)
    most_followed_qs = QuestionsDatabase.instance.execute(<<-SQL, n)
      SELECT
        *
      FROM 
        questions
      JOIN
        users ON questions.author_id = users.id
      WHERE questions.id  IN (
        SELECT
          question_id
        FROM
          question_follows
        GROUP BY question_id
        ORDER BY COUNT(user_id) DESC
        LIMIT ?      
      )
    SQL
    
    return nil if most_followed_qs.empty? 
    
    most_followed_qs.map { |q| Question.new(q) }
  end
end

class Reply
  attr_accessor :question_id, :reply_id, :user_id, :body
  
  def self.find_by_user_id(user_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, user_id)
      SELECT
        *
      FROM
        replies
      WHERE
        user_id = ?
    SQL
    
    return nil if reply.empty?
    
    reply.map { |r| Reply.new(r) }
  end 
  
  def self.find_by_question_id(question_id)
    quest = QuestionsDatabase.instance.execute(<<-SQL, question_id)
      SELECT
        *
      FROM
        replies
      WHERE
        question_id = ?
    SQL
    
    return nil if quest.empty?
    
    quest.map { |q| Reply.new(q) }
  end 
  
  def self.find_by_reply_id(reply_id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, reply_id)
      SELECT
        *
      FROM
        replies
      WHERE
        reply_id = ?
    SQL
    
    return nil if reply.empty?
    
    reply.map { |q| Reply.new(q) }
  end 
  
  def self.find_by_id(id)
    reply = QuestionsDatabase.instance.execute(<<-SQL, id)
      SELECT
        *
      FROM
        replies
      WHERE
        id = ?
    SQL
    
    return nil if reply.empty?
    
    reply.map { |q| Reply.new(q) }
  end 
  
  def initialize(options)
    @id = options['id']
    @question_id = options['question_id']
    @reply_id = options['reply_id']
    @user_id = options['user_id']
    @body = options['body']
  end 
  
  def create
    raise "#{self} already in database" if @id
    QuestionsDatabase.instance.execute(<<-SQL, @question_id, @reply_id, @user_id, @body)
      INSERT INTO
        replies (question_id, reply_id, user_id, body)
      VALUES
        (?, ?, ?, ?)
    SQL
    @id = QuestionsDatabase.instance.last_insert_row_id
  end
  
  def author
    User.find_by_id(@user_id)
  end
  
  def question
    Question.find_by_question(@question_id)
  end
  
  def parent_reply
    raise 'This is the parent id' unless @reply_id
    Reply.find_by_id(@reply_id)
  end 
  
  def child_replies
    raise "Not yet created" unless @id
    Reply.find_by_reply_id(@id)
  end
end