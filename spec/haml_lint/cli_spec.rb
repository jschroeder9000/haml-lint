require 'spec_helper'
require 'haml_lint/cli'

describe HamlLint::CLI do
  let(:io) { StringIO.new }
  let(:output) { io.string }
  let(:logger) { HamlLint::Logger.new(io) }
  let(:cli) { described_class.new(logger) }

  describe '#run' do
    subject { cli.run(args) }
    let(:args) { [] }
    let(:options) { HamlLint::Options.new }

    it 'passes the arguments to the Options#parse method' do
      HamlLint::Options.any_instance.should_receive(:parse).with(args)
      subject
    end

    context 'when no arguments are given' do
      before { HamlLint::Runner.any_instance.stub(:run) }

      it 'scans for lints' do
        HamlLint::Runner.any_instance.should_receive(:run)
        subject
      end
    end

    context 'when arguments are given' do
      let(:args) { %w[file.haml some-view-*.haml] }

      before { HamlLint::Runner.any_instance.stub(:run) }

      it 'scans for lints' do
        HamlLint::Runner.any_instance.should_receive(:run)
        subject
      end
    end

    context 'when passed the --color flag' do
      let(:args) { ['--color'] }

      it 'sets the logger to output in color' do
        subject
        logger.color_enabled.should == true
      end

      context 'and the output stream is not a TTY' do
        before do
          io.stub(:tty?).and_return(false)
        end

        it 'sets the logger to output in color' do
          subject
          logger.color_enabled.should == true
        end
      end
    end

    context 'when passed the --no-color flag' do
      let(:args) { ['--no-color'] }

      it 'sets the logger to not output in color' do
        subject
        logger.color_enabled.should == false
      end
    end

    context 'when --[no-]color flag is not specified' do
      before do
        io.stub(:tty?).and_return(tty)
      end

      context 'and the output stream is a TTY' do
        let(:tty) { true }

        it 'sets the logger to output in color' do
          subject
          logger.color_enabled.should == true
        end
      end

      context 'and the output stream is not a TTY' do
        let(:tty) { false }

        it 'sets the logger to not output in color' do
          subject
          logger.color_enabled.should == false
        end
      end
    end

    context 'when passed the --show-linters flag' do
      let(:args) { ['--show-linters'] }

      let(:fake_linter) do
        linter = double('linter')
        linter.stub(:name).and_return('FakeLinter')
        linter
      end

      before do
        HamlLint::LinterRegistry.stub(:linters).and_return([fake_linter])
      end

      it 'displays the available linters' do
        subject
        output.should include 'FakeLinter'
      end

      it { should == Sysexits::EX_OK }
    end

    context 'when passed the --version flag' do
      let(:args) { ['--version'] }

      it 'displays the application name' do
        subject
        output.should include HamlLint::APP_NAME
      end

      it 'displays the version' do
        subject
        output.should include HamlLint::VERSION
      end
    end

    context 'when invalid argument is given' do
      let(:args) { ['--some-invalid-argument'] }

      it 'displays message about invalid option' do
        subject
        output.should =~ /invalid option/i
      end

      it { should == Sysexits::EX_USAGE }
    end

    context 'when an unhandled exception occurs' do
      let(:backtrace) { %w[file1.rb:1 file2.rb:2] }
      let(:error_msg) { 'Oops' }

      let(:exception) do
        StandardError.new(error_msg).tap { |e| e.set_backtrace(backtrace) }
      end

      before { cli.stub(:act_on_options).and_raise(exception) }

      it 'displays error message' do
        subject
        output.should include error_msg
      end

      it 'displays backtrace' do
        subject
        output.should include backtrace.join("\n")
      end

      it 'displays link to bug report URL' do
        subject
        output.should include HamlLint::BUG_REPORT_URL
      end

      it { should == Sysexits::EX_SOFTWARE }
    end
  end
end
