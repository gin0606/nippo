require 'octokit'

USER_NAME = ENV['NIPPO_GITHUB_USER_NAME']

class Nippo
  def initialize(date: nil)
    # TODO: 渡されたdateでselectする
  end

  def pull_requests
    @pull_requests ||= PullRequests.new(user_events + user_public_events)
  end

  def client
    @@client = Octokit::Client.new(login: USER_NAME, access_token: ENV['NIPPO_GITHUB_API_TOKEN'])
  end

  def user_events
    @@user_events ||= client.user_events(USER_NAME)
  end

  def user_public_events
    @@user_public_events ||= client.user_public_events(USER_NAME)
  end

  class Events
    def initialize(events)
      @events = events
    end

    protected
    def list
      @events.select{|event| event.type == self.type}
    end

    def events_by_action(action)
      list.select{|event| event.payload.action == action}
    end
  end

  module IssueBaseEvents
    def assigned
      events_by_action('assigned')
    end

    def unassigned
      events_by_action('unassigned')
    end

    def labeled
      events_by_action('labeled')
    end

    def unlabeled
      events_by_action('unlabeled')
    end

    def opened
      events_by_action('opened')
    end

    def closed
      events_by_action('closed')
    end

    def reopened
      events_by_action('reopened')
    end

    def synchronize
      events_by_action('synchronize')
    end
  end

  class PullRequests < Events
    include IssueBaseEvents

    def type
      'PullRequestEvent'
    end

    def all
      list
    end

    def merged
      closed.select{|event| event.payload.pull_request.merged}
    end

    def unmerged
      closed.select{|event| !event.payload.pull_request.merged}
    end
  end
end

nippo = Nippo.new(date: Date.today)
puts '* pull_request' unless nippo.pull_requests.all.empty?
puts '  * merged' unless nippo.pull_requests.merged.empty?
nippo.pull_requests.merged.each do |pull_request|
  puts "    * #{pull_request.payload.pull_request.title}"
end
puts '  * rejected' unless nippo.pull_requests.unmerged.empty?
nippo.pull_requests.unmerged.each do |pull_request|
  puts "    * #{pull_request.payload.pull_request.title}"
end
puts '  * opened' unless nippo.pull_requests.opened.empty?
nippo.pull_requests.opened.each do |pull_request|
  puts "    * #{pull_request.payload.pull_request.title}"
end

# client = Octokit::Client.new(login: USER_NAME, access_token: ENV['NIPPO_GITHUB_API_TOKEN'])
#
# events = []
# events.concat client.user_events(USER_NAME)
# events.concat client.user_public_events(USER_NAME)
#
# activities = {}
# comments = {}
#
# events.each do |event|
#   break unless event.created_at.getlocal.to_date == Time.now.to_date
#   case event.type
#   when "IssuesEvent"
#     issue = activities[:issue] ||= {}
#     issue[event.payload.issue.html_url] ||= {title: event.payload.issue.title}
#     if event.payload.action == "opened"
#       action = issue[event.payload.issue.html_url][:action]
#       issue[event.payload.issue.html_url][:action] = "opened" unless action == "closed"
#     elsif  event.payload.action == "closed"
#       issue[event.payload.issue.html_url][:action] = "closed"
#     end
#   when "IssueCommentEvent"
#     issue_comments = comments[:issue_comments] ||= {}
#     issue_comments[event.payload.issue.html_url] ||= {title: event.payload.issue.title, comments: []}
#     issue_comments[event.payload.issue.html_url][:comments] << event.payload.comment.html_url
#   when "PullRequestEvent"
#     pull_request = activities[:pull_request] ||= {}
#     pull_request[event.payload.pull_request.html_url] ||= {title: event.payload.pull_request.title}
#     if event.payload.action == "opened"
#       action = pull_request[event.payload.pull_request.html_url][:action]
#       pull_request[event.payload.pull_request.html_url][:action] = "opened" unless action == "merged" or action == "rejected"
#     elsif  event.payload.action == "closed"
#       if event.payload.pull_request.merged
#         pull_request[event.payload.pull_request.html_url][:action] = "merged"
#       else
#         pull_request[event.payload.pull_request.html_url][:action] = "rejected"
#       end
#     end
#   when "PullRequestReviewCommentEvent"
#     review_comments = comments[:review_comments] ||= {}
#     review_comments[event.payload.pull_request.html_url] ||= {title: event.payload.pull_request.title, comments: []}
#     review_comments[event.payload.pull_request.html_url][:comments] << event.payload.comment.html_url
#   end
# end
#
# activities.each do |k, v|
#   puts "* #{k}"
#   tmp = {}
#   v.each do |_k, _v|
#     tmp[_v[:action]] ||= {}
#     tmp[_v[:action]][_k] = _v
#   end
#   tmp.each do |_k, _v|
#     puts "    * #{_k}"
#     _v.each do |__k, __v|
#       puts "        * [#{__v[:title]}](#{__k})"
#     end
#   end
# end

# puts "* comments" unless comments.empty?
# comments.each do |k, v|
#   puts "    * #{k}"
#   v.each do |_k, _v|
#     puts "      * [#{_v[:title]}](#{_k})"
#     _v[:comments].each do |comment|
#       puts "          * #{comment}"
#     end
#   end
# end
