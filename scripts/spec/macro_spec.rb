require_relative "../lib/macro_if_tracker"

describe 'MacroIfTracker', MacroIfTracker do
  context 'Parse if def' do

    it 'should detect basic if def' do
      tracker = MacroIfTracker.new
      expect(tracker.is_ifdef("foo")).to eq(false)
      expect(tracker.is_ifdef("#ifdef FOO")).to eq(true)
      expect(tracker.is_ifdef("#if defined(BAR)")).to eq(true)
    end

    it 'should detect basic if not def' do
      tracker = MacroIfTracker.new
      expect(tracker.is_ifdef("foo")).to eq(false)
      expect(tracker.is_ifdef("#ifndef FOO")).to eq(true)
      expect(tracker.is_ifdef("#if !defined(BAR)")).to eq(true)
    end

    it 'should not detect commented out if def' do
      tracker = MacroIfTracker.new
      expect(tracker.is_ifdef("// #if defined(COMMENTED_OUT)")).to eq(false)
    end

    it 'should not detect syntax error if def' do
      tracker = MacroIfTracker.new
      expect(tracker.is_ifdef("#if def BADSPACE")).to eq(false)
    end

    it 'should not detect if the hashtag is missing' do
      tracker = MacroIfTracker.new
      expect(tracker.is_ifdef("if defined")).to eq(false)
    end

    it 'should detect spaced if defs' do
      tracker = MacroIfTracker.new
      expect(tracker.is_ifdef("#   if    defined     (YEE)")).to eq(true)
    end
  end

  context 'Track nesting' do
    it 'should grow stack to 3 on tripple nest' do
      tracker = MacroIfTracker.new
      tracker.add_line("// hello world")
      tracker.add_line("#ifdef WINDOWS")
      tracker.add_line("#ifdef FOO")
      tracker.add_line("#ifdef FOO")
      expect(tracker.stack.length).to eq(3)
    end

    it 'should pop stack back to 0' do
      tracker = MacroIfTracker.new
      tracker.add_line("// hello world")
      tracker.add_line("#ifdef WINDOWS")
      tracker.add_line("#ifdef FOO")
      tracker.add_line("#ifdef FOO")
      expect(tracker.stack.length).to eq(3)
      tracker.add_line("#endif")
      tracker.add_line("#endif")
      tracker.add_line("#endif")
      expect(tracker.stack.length).to eq(0)
    end
  end
end
