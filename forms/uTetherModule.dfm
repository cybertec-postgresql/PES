object dmTether: TdmTether
  OldCreateOrder = False
  Height = 428
  Width = 529
  object TetherManager: TTetheringManager
    OnPairedFromLocal = TetherManagerPairedFromLocal
    OnRequestManagerPassword = TetherManagerRequestManagerPassword
    Password = 'cybertec'
    Text = 'TetherManager'
    AllowedAdapters = 'Network_V4'
    Left = 64
    Top = 24
  end
  object TetheringAppProfile: TTetheringAppProfile
    Manager = TetherManager
    Text = 'TetheringAppProfile'
    Group = 'PES'
    Actions = <
      item
        Name = 'acFullShot'
        IsPublic = True
        NotifyUpdates = False
      end
      item
        Name = 'acStartCast'
        IsPublic = True
        NotifyUpdates = False
      end
      item
        Name = 'acStopCast'
        IsPublic = True
        NotifyUpdates = False
      end>
    Resources = <>
    Left = 64
    Top = 105
  end
end
