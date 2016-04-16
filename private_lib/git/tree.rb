require 'pathname'

class Node
  attr_accessor :sha, :name, :parent, :children
  
  def initialize(name, sha, parent = nil)
    self.name = name
    self.sha = sha
    self.parent = parent
    self.children = []
  end
  
  def path
    if self.parent && !self.parent.root?
      File.join(self.parent.path, self.name)
    else
      self.name
    end
  end
  
  def absolute_path
    if self.parent
      File.join(self.parent.absolute_path, self.name)
    else
      File.join(Git.root, self.name)
    end
  end
  
  def descend(&block)
    block[self]
    self.descend_children(&block)
  end
  
  def descend_children(&block)
    self.children.each { |c| c.descend(&block) }
  end
  
  def root?
    false
  end
  
  # Parses a node from `git ls-tree`
  def self.tokenize(line)
    line.match(/(?<mode>\S+) (?<type>\S+) (?<sha>\S+)\t(?<path>.*)/)
  end
  
  def [](path)
    path.split(File::SEPARATOR).inject(self) do |parent, part|
      if parent
        parent.children.find { |c| c.name == part }
      else
        nil
      end
    end
  end
end

class Blob < Node
  def type
    'blob'
  end
end

class Tree < Node
  def type
    'tree'
  end
  
  class Root < Tree
    def path
      Git.root
    end
    alias absolute_path path
    
    def root?
      true
    end
  end
  
  def self.head
    self.from_ref('HEAD')
  end
  
  def self.from_ref(ref)
    tree = Root.new(ref, Git.rev_parse(ref))
    files = nil
    Dir.chdir(Git.root) do
      `git ls-tree -r -t #{ref}`.split("\n").map { |line|
        line.strip
      }.select { |line|
        line && line.length > 0
      }.each { |line|
        tokens = Node.tokenize(line)
        name = File.basename(tokens['path'])
        
        new_node = tokens['type'] == 'blob' ?
          Blob.new(name, tokens['sha']) :
          Tree.new(name, tokens['sha'])
        
        new_node.parent = tokens['path'].include?(File::SEPARATOR) ?
        tree[File.dirname(tokens['path'])] :
        tree
        
        new_node.parent.children.push(new_node)
      }
    end
    
    tree
  end
end
