guard :rspec, cmd: 'rspec' do
  watch(%r{^lib/(.+)\.rb$}) { |m| "spec/lib/#{m[:path]}_spec.rb" }
  watch %r{^spec/.+(_spec|Spec)}
end
