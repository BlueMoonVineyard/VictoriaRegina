set positional-arguments

default:
	just --justfile {{justfile()}} --list

# builds all projects
build-all:
	cd Civ && ./gradlew build

# builds the given project
build PROJECT:
	cd Civ && ./gradlew :plugins:{{PROJECT}}:build

# copies all projects to their right folders
copy-all:
	just --justfile {{justfile()}} copy banstick
	just --justfile {{justfile()}} copy bastion
	just --justfile {{justfile()}} copy citadel
	just --justfile {{justfile()}} copy civchat2
	just --justfile {{justfile()}} copy civduties
	just --justfile {{justfile()}} copy civmodcore
	just --justfile {{justfile()}} copy civspy
	just --justfile {{justfile()}} copy combattagplus
	just --justfile {{justfile()}} copy essenceglue
	just --justfile {{justfile()}} copy exilepearl
	just --justfile {{justfile()}} copy factorymod
	just --justfile {{justfile()}} copy finale
	just --justfile {{justfile()}} copy hiddenore
	just --justfile {{justfile()}} copy itemexchange
	just --justfile {{justfile()}} copy jukealert
	just --justfile {{justfile()}} copy kirabukkitgateway
	just --justfile {{justfile()}} copy namecolors
	just --justfile {{justfile()}} copy namelayer
	just --justfile {{justfile()}} copy namelayer
	just --justfile {{justfile()}} copy railswitch
	just --justfile {{justfile()}} copy randomspawn
	just --justfile {{justfile()}} copy realisticbiomes
	just --justfile {{justfile()}} copy simpleadminhacks

# copy a project from the Civ build to the Builds folder
copy PROJECT:
	#!/usr/bin/env perl

	use strict;
	use warnings;
	use File::Copy;

	my $regex = '{{PROJECT}}-(paper|bungee|api)-([0-9]+\.[0-9]+\.[0-9]+(-SNAPSHOT)?).jar';

	my @files = grep m/$regex/, glob("Civ/plugins/*/build/libs/{{PROJECT}}*");

	foreach my $file ( @files ) {
		$file =~ m/$regex/;

		my %dirs = (
			paper => 'Builds/Paper',
			bungee => 'Builds/BungeeCord',
			api => 'Builds/API',
		);

		copy($files[0], "$dirs{$1}/{{PROJECT}}.jar");
		open(my $fh, '>', "$dirs{$1}/{{PROJECT}}.version.txt");
		print $fh $2, "\n";
		close($fh);
	}

# generate ssh-config for sftp
ssh-config:
	#!/usr/bin/env perl

	use YAML::XS qw(Load);
	use File::Slurp qw(write_file);

	my $secrets = `ansible-vault view secrets`;
	my %data = %{ Load $secrets };

	my $config = sprintf "Host civunion\n\tHostName %s\n\tPort %d\n\tUser %s\n", $data{'sftp'}{'host'}, $data{'sftp'}{'port'}, $data{'sftp'}{'user'};

	write_file("ssh-config", { binmode => ':raw' }, $config);

# connect via SFTP
sftp:
	#!/usr/bin/env perl

	use YAML::XS qw(Load);

	my $secrets = `ansible-vault view secrets`;
	my %data = %{ Load $secrets };

	system("sshpass", "-p", $data{'sftp'}{'pass'}, "sftp", "-F", "ssh-config", "civunion");

upload-paper-all:
	just --justfile {{justfile()}} upload-paper banstick bastion citadel civchat2 civduties civmodcore civspy combattagplus essenceglue exilepearl factorymod finale hiddenore itemexchange jukealert kirabukkitgateway namecolors namelayer namelayer railswitch randomspawn realisticbiomes simpleadminhacks BreweryNG

# upload paper plugins
upload-paper +args:
	#!/usr/bin/env perl

	my @args;

	foreach my $arg (@ARGV) {
		my $jar = sprintf "Builds/Paper/%s.jar", $arg;
		my $ver = sprintf "Builds/Paper/%s.version.txt", $arg;
		push(@args, $jar, $ver);
	}

	use YAML::XS qw(Load);

	my $secrets = `ansible-vault view secrets`;
	my %data = %{ Load $secrets };

	system("sshpass", "-p", $data{'sftp'}{'pass'}, "scp", "-F", "ssh-config", @args, "civunion:/plugins/");

# download paper plugins
download-paper +args:
	#!/usr/bin/env perl

	use YAML::XS qw(Load);
	use File::Slurp qw(read_file write_file);

	my $yaml = read_file "paper-plugins.yml";
	my %plugins = %{ Load $yaml };

	foreach my $arg (@ARGV) {
		my %plugin = %{$plugins{$arg}};
		print %plugin;
		system("wget", $plugin{'url'}, "-O", "Builds/Paper/" . $arg . ".jar");
		write_file("Builds/Paper/" . $arg . ".version.txt", { binmode => ':raw' }, $plugin{'version'});
	}

# build the config files
build-config:
	cp -r PrivateConfig/* BuiltConfig/
	cp -r Config/* BuiltConfig/

# upload built config to the server
upload-config:
	#!/usr/bin/env perl

	use YAML::XS qw(Load);

	my $secrets = `ansible-vault view secrets`;
	my %data = %{ Load $secrets };

	system("sshpass", "-p", $data{'sftp'}{'pass'}, "scp", "-r", "-F", "ssh-config", glob("BuiltConfig/*"), "civunion:/plugins/");
