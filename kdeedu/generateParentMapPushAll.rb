prefix = 'scratch/ianmonroe/' #make empty when final

ENV['bindir'] = Dir.pwd + "/../bin"
Dir.mkdir("repos")
Dir.mkdir("logs")

repos = ["blinken",
"cantor",
"kalgebra",
"kalzium",
"kanagram",
"kbruch",
"kgeography",
"khangman",
"kig",
"kiten",
"klettres",
"kmplot",
"kstars",
"ktouch",
"kturtle",
"kwordquiz",
"libkdeedu",
"marble",
"parley",
"rocs",
"step"]

rulesDir = Dir.pwd

Dir.chdir("repos")
repos.each { |project|
  `../createrepo-psql ../#{project}-rules #{Time.new.strftime("%m%d.%H%M")}-#{project}`
  puts "Created repo #{project}"
}
Dir.chdir(rulesDir)

repos.each { |project|
    if File.exists?("#{project}-parentmap") then
        Dir.chdir("repos/#{project}")
        `../../parent-adder ../../#{project}-parentmap`
        puts "Added parents for #{project}"
        Dir.chdir(rulesDir)
    end
}

repos.each { |project|
    if File.exists?("#{project}-filter") then
        Dir.chdir("repos/#{project}")
	`../../#{project}-filter`
        puts "Filtered #{project}"
        Dir.chdir(rulesDir)
    end
}

repos.each { |project|
    Dir.chdir("repos/#{project}")
    `git gc --aggressive`
    `ssh git@git.kde.org trash #{prefix}#{project}`
    `git push --all git@git.kde.org:#{prefix}#{project}`
    `git push --tags git@git.kde.org:#{prefix}#{project}`
    Dir.chdir(rulesDir)
}

