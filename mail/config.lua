options.certificates = false
options.limit        = 50
options.range        = 50
options.subscribe    = true

account = IMAP {
    server   = os.getenv("MAIL_SERVER"),
    username = os.getenv("MAIL_USERNAME"),
    password = os.getenv("MAIL_PASSWORD"),
    ssl      = "auto"
}

function fromToFilter(address, folder)
    local fromResults =
        account["INBOX"]:contain_from(address) +
        account["INBOX"]:match_from(address)

    fromResults:move_messages(account[folder])

    local toResults =
        account["INBOX"]:contain_to(address) +
        account["INBOX"]:match_to(address) +
        account["INBOX"]:contain_cc(address) +
        account["INBOX"]:match_cc(address)

    toResults:move_messages(account[folder])
end

function listIdFilter(listId, folder)
    local results =
        account["INBOX"]:contain_field("List-ID", listId) +
        account["INBOX"]:match_field("List-ID", listId) +
        account["INBOX"]:contain_field("List-Id", listId) +
        account["INBOX"]:match_field("List-Id", listId) +
        account["INBOX"]:contain_field("List-Subscribe", listId) +
        account["INBOX"]:match_field("List-Subscribe", listId) +
        account["INBOX"]:match_field("Mailing-List", listId) +
        account["INBOX"]:contain_field("Mailing-List", listId) +
        account["INBOX"]:contain_field("Sender", listId) +
        account["INBOX"]:match_field("Sender", listId) +
        account["INBOX"]:contain_field("X-BeenThere", listId) +
        account["INBOX"]:match_field("X-BeenThere", listId) +
        account["INBOX"]:contain_field("X-Mailinglist", listId) +
        account["INBOX"]:match_field("X-Mailinglist", listId)

    results:move_messages(account[folder])
end

function spamFilter()
    local blacklist =
        account["INBOX"]:contain_field("X-HE-Spam-Score", "99") +
        account["INBOX"]:match_field("X-HE-Spam-Score", "99")

    blacklist:delete_messages()

    local maybeSPAM =
        account["INBOX"]:contain_field("X-SPAM-FLAG", "Yes") +
        account["INBOX"]:match_field("X-SPAM-FLAG", "Yes")

    maybeSPAM:move_messages(account["spambucket"])
end

function removeOld(folder, days)
    local results = account[folder]:sent_before(form_date(days))

    results:delete_messages()
end

function blacklist(address)
    local results =
        account["INBOX"]:contain_from(address) +
        account["INBOX"]:match_from(address) +
        account["INBOX"]:contain_to(address) +
        account["INBOX"]:match_to(address) +
        account["INBOX"]:contain_cc(address) +
        account["INBOX"]:match_cc(address)

    results:delete_messages()
end

function moveOld(folder, days)
    local date = form_date(days)
    local localArchive = "Archives/" .. string.gsub(folder, "(INBOX/)", "")
    local results = account[folder]:sent_before(date)

    results:move_messages(account[localArchive])
    account:subscribe_mailbox(localArchive)
end

function contains(e, t)
    for i = 1, #t, 1 do
        if t[i] == e then
            return true
        end
    end

    return false
end

function removeDuplicate(folder)
    local all = account[folder]:sent_before(form_date(0))
    local seen = {}
    local results = Set {}

    for _, message in ipairs(all) do
        local mbox, uid = unpack(message)
        local message_id = mbox[uid]:fetch_field("Message-ID")

        if contains(message_id, seen) then
            table.insert(results, message)
        else
            table.insert(seen, message_id)
        end
    end

    results:delete_messages()
    account:subscribe_mailbox(folder)
end

function cleanFolder()
    local folders, _ = account:list_all("", "*")

    for _, folder in ipairs(folders) do
        if folder ~= "INBOX"
            and folder ~= "Drafts"
            and folder ~= "Templates"
            and folder ~= "Trash" then
            if string.sub(folder, 1, string.len("Archives")) ~= "Archives" then
                removeDuplicate(folder, 0)
                moveOld(folder, 30)
            end
        end

        removeOld(folder, 365 * 5 + 3)
    end
end

while true do
    spamFilter()

    results = account["Sent"]:select_all()
    results:mark_seen()

    fromToFilter("donnerwetter.de", "news")

    listIdFilter("tsc-marburg.(google|yahoo)groups.(de|com)", "community")

    fromToFilter("amazon.(com|de|uk)", "commerce")
    fromToFilter("apple.(com|de)", "commerce")
    fromToFilter("dashlane.com", "commerce")
    fromToFilter("@dhl.(com|de)", "commerce")
    fromToFilter("dpd.de", "commerce")
    fromToFilter("github.com", "commerce")
    fromToFilter("google.(com|de)", "commerce")
    fromToFilter("(hetzner(|-status)|konsoleh).(com|de)", "commerce")
    fromToFilter("hosteurope.de", "commerce")
    fromToFilter("(o2(|online)|telefonica).(com|de)", "commerce")
    fromToFilter("paypal.(com|de)", "commerce")
    fromToFilter("timesheet.io", "commerce")
    fromToFilter("(t-mobile|telekom).(com|de)", "commerce")

    removeOld("spambucket", 15)
    removeOld("Trash", 30)

    cleanFolder()

    account["INBOX"]:enter_idle()
end
