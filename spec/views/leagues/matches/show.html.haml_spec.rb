require 'rails_helper'

describe 'leagues/matches/show' do
  context 'home team has more players' do
    let(:div) { create(:league_division) }
    let(:home_team) { create(:league_roster, division: div, player_count: 4) }
    let(:away_team) { create(:league_roster, division: div, player_count: 2) }
    let(:match) { create(:league_match, home_team: home_team, away_team: away_team) }

    it 'displays all players' do
      assign(:league, div.league)
      assign(:match, match)

      render

      home_team.users.each do |user|
        expect(rendered).to include(user.name)
      end
      away_team.users.each do |user|
        expect(rendered).to include(user.name)
      end
    end
  end

  context 'away team has more players' do
    let(:div) { create(:league_division) }
    let(:home_team) { create(:league_roster, division: div, player_count: 3) }
    let(:away_team) { create(:league_roster, division: div, player_count: 4) }
    let(:match) { create(:league_match, home_team: home_team, away_team: away_team) }

    it 'displays all players' do
      assign(:league, div.league)
      assign(:match, match)

      render

      home_team.users.each do |user|
        expect(rendered).to include(user.name)
      end
      away_team.users.each do |user|
        expect(rendered).to include(user.name)
      end
    end
  end

  context 'BYE match' do
    let(:match) { build(:bye_league_match) }

    it 'displays' do
      assign(:league, match.league)
      assign(:match, match)

      render
    end
  end

  context 'standard match' do
    let(:match) { create(:league_match) }
    let(:user) { create(:user) }
    let!(:comms) { create_list(:league_match_comm, 6, match: match) }

    before do
      assign(:league, match.league)
      assign(:match, match)
      assign(:comm, League::Match::Comm.new(match: match))

      days = Array.new(5, true) + Array.new(2, false)
      scheduler = build(:league_schedulers_weekly, days: days, minimum_selected: 3)
      match.league.update!(schedule: 'weeklies', weekly_scheduler: scheduler)

      schedule = { 'type' => 'weekly', 'availability' => {
        'Sunday' => 'true', 'Monday' => 'true', 'Tuesday' => 'true' } }
      match.home_team.update!(schedule_data: schedule)

      schedule['availability'] = {
        'Tuesday' => 'true', 'Wednesday' => 'true', 'Thursday' => 'true' }
      match.away_team.update!(schedule_data: schedule)
    end

    it 'displays for home team captains' do
      user.grant(:edit, match.home_team.team)
      sign_in user

      render
    end

    it 'displays for away team captains' do
      user.grant(:edit, match.away_team.team)
      sign_in user

      render
    end

    it 'displays for admins' do
      user.grant(:edit, match.league)
      sign_in user

      render
    end

    it 'displays for unauthorized user' do
      sign_in user

      render
    end

    it 'displays for unauthenticated user' do
      render
    end

    after do
      expect(rendered).to include('Tuesday')
      comms.each do |comm|
        expect(rendered).to include(comm.content)
      end
    end
  end
end
