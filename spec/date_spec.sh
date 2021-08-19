#shellcheck shell=sh

Describe 'date.sh'
  Include locals.sh
  Include date.sh

  Describe 'human_period'
    It "Returns minutes"
      When call human_period 120
      The output should eq "2 minutes"
    End

    It "Returns minute"
      When call human_period 60
      The output should eq "1 minute"
    End

    It "Returns hours"
      When call human_period 7200
      The output should eq "2 hours"
    End

    It "Returns hour"
      When call human_period 3600
      The output should eq "1 hour"
    End

    It "Returns day"
      When call human_period 86400
      The output should eq "1 day"
    End

    It "Returns days"
      When call human_period 259200
      The output should eq "3 days"
    End

    It "Returns seconds"
      When call human_period 5
      The output should eq "5 seconds"
    End

    It "Returns second"
      When call human_period 1
      The output should eq "1 second"
    End

    It "Returns 0 seconds"
      When call human_period 0
      The output should eq "0 seconds"
    End

    It "Understands more complex periods"
      When call human_period 266520
      The output should eq "3 days 2 hours 2 minutes"
    End

    It "Skips seconds for long periods"
      When call human_period 266525
      The output should eq "3 days 2 hours 2 minutes"
    End
  End
End