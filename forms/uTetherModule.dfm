object dmTether: TdmTether
  OldCreateOrder = False
  Height = 428
  Width = 529
  object TetherManager: TTetheringManager
    OnPairedFromLocal = TetherManagerPairedFromLocal
    OnRequestManagerPassword = TetherManagerRequestManagerPassword
    Password = 'cybertec'
    Text = 'TetherManager'
    AllowedAdapters = 'Network'
    Left = 64
    Top = 24
  end
  object TetheringAppProfile: TTetheringAppProfile
    Manager = TetherManager
    Text = 'TetheringAppProfile'
    Group = 'PES'
    Actions = <>
    Resources = <>
    Left = 64
    Top = 105
  end
end
