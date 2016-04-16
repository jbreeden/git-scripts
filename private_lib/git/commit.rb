class Commit
  attr_accessor :sha,
    :tree_sha,
    :parents,
    :author_name,
    :author_email,
    :author_date,
    :committer_name,
    :committer_email,
    :committer_date,
    :title

  # revision should be a single line as generated by `git log --pretty=format:"%H,%T,%P,%an,%ae,%ad,%cn,%ce,%cd,%s"`
  def self.parse(revision)
    tokens = revision.split(',')
    c = Commit.new
    c.sha = tokens[0]
    c.tree_sha = tokens[1]
    c.parents = tokens[2].split(/\s+/)
    c.author_name = tokens[3]
    c.author_email = tokens[4]
    c.author_date = tokens[5]
    c.committer_name = tokens[6]
    c.committer_email = tokens[7]
    c.committer_date = tokens[8]
    # If the commit title had a ',', it was split. Re-join it before storing
    c.title = tokens[9..(tokens.length-1)].join(',')
    c
  end

  # For easy serializtion (make a hash, add attributes as needed, then .to_json it)
  def to_h
    {
      :sha => self.sha,
      :tree_sha => self.tree_sha,
      :parents => self.parents,
      :author_name => self.author_name,
      :author_email => self.author_email,
      :author_date => self.author_date,
      :committer_name => self.committer_name,
      :committer_email => self.committer_email,
      :committer_date => self.committer_date,
      :title => self.title
    }
  end
end