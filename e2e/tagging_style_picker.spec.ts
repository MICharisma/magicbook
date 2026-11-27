import { test, expect } from '@playwright/test'
import { isLocalMagicbook, signInAsListOwner } from './helpers'

test.describe('tag style picker', () => {
  test('shows the chosen style on the trigger and closes the menu', async ({ page }) => {
    test.skip(!isLocalMagicbook(), 'needs a local owner session, not staging')

    await signInAsListOwner(page)
    await page.goto('/lists/219-Hobbit-Characters', { waitUntil: 'domcontentloaded' })

    await page.locator('.list > .tagging').getByRole('button', { name: 'Tags' }).click()

    const picker = page.locator('#create_tag_list_219 .tagging-style-picker')
    const trigger = picker.locator('[data-create-tag-target="trigger"]')
    const menu = picker.locator('[data-create-tag-target="menu"]')

    await expect(trigger).toHaveText('#')
    await expect(trigger).toHaveAttribute('aria-label', 'Choose a style')
    await expect(menu).toBeHidden()

    await trigger.click()
    await expect(menu).toBeVisible()
    await expect(trigger).toHaveAttribute('aria-expanded', 'true')

    await menu.getByRole('option', { name: 'Format' }).click()

    await expect(menu).toBeHidden()
    await expect(trigger).toHaveAttribute('aria-expanded', 'false')
    await expect(trigger).toHaveText('Format')
    await expect(trigger).toHaveAttribute('aria-label', 'Style: Format')
    await expect(menu.locator('[data-style-name="Format"]')).toHaveAttribute('aria-selected', 'true')
  })

  test('keeps listed-item tagging closed until the tag icon is clicked', async ({ page }) => {
    test.skip(!isLocalMagicbook(), 'needs a local owner session, not staging')

    await signInAsListOwner(page)
    await page.goto('/lists/219-Hobbit-Characters', { waitUntil: 'domcontentloaded' })

    const item = page.locator('.listed_item').first()
    const toggle = item.getByRole('button', { name: 'Tags' })
    const panel = item.locator('.tagging-panel')

    await expect(toggle).toBeVisible()
    await expect(panel).toBeHidden()
    await expect(item.locator('.tagging-disclosure-panel .tagging-applied')).toHaveCount(0)

    await toggle.click()
    await expect(panel).toBeVisible()
    await expect(toggle).toHaveAttribute('aria-expanded', 'true')
  })

  test('shows applied item chips without opening the picker', async ({ page }) => {
    test.skip(!isLocalMagicbook(), 'needs a local owner session, not staging')

    await signInAsListOwner(page)
    await page.goto('/lists/219-Hobbit-Characters', { waitUntil: 'domcontentloaded' })

    const item = page.locator('.listed_item').filter({ hasText: 'Smaug' }).first()
    const chip = item.locator('.tagging-applied .tagging-chip').first()

    await expect(chip).toBeVisible()
    await expect(item.locator('.tagging-panel')).toBeHidden()

    const nameBox = await item.locator('.designation_of_listed_item').boundingBox()
    const chipBox = await chip.boundingBox()
    expect(nameBox).toBeTruthy()
    expect(chipBox).toBeTruthy()
    expect(chipBox!.x).toBeGreaterThan(nameBox!.x)
  })

  test('shows applied list chips without opening the picker', async ({ page }) => {
    test.skip(!isLocalMagicbook(), 'needs a local owner session, not staging')

    await signInAsListOwner(page)
    await page.goto('/lists/219-Hobbit-Characters', { waitUntil: 'domcontentloaded' })

    const chips = page.locator('.list > .tagging > .tagging-applied .tagging-chip')
    await expect(chips.first()).toBeVisible()
    await expect(page.locator('#create_tag_list_219')).toBeHidden()
  })

  test('keeps the tag composer compact and extra tags behind More', async ({ page }) => {
    test.skip(!isLocalMagicbook(), 'needs a local owner session, not staging')

    await signInAsListOwner(page)
    await page.goto('/lists/219-Hobbit-Characters', { waitUntil: 'domcontentloaded' })
    await page.locator('.list > .tagging').getByRole('button', { name: 'Tags' }).click()

    const panel = page.locator('.list > .tagging .tagging-panel')
    await expect(panel).toBeVisible()
    await expect(panel.getByRole('heading', { name: 'Apply an existing tag' })).toHaveCount(0)
    await expect(panel.getByText('Find a tag')).toHaveCount(0)
    await expect(panel.getByText('Create one below')).toHaveCount(0)

    const box = await panel.boundingBox()
    expect(box).toBeTruthy()
    expect(box!.width).toBeLessThanOrEqual(320)

    const prospective = panel.locator('.tagging-option.is-styled').first()
    if (await prospective.count()) {
      await expect(prospective.locator('.tagging-chip-context')).toBeVisible()
      await expect(prospective.locator('.tagging-chip-name')).toBeVisible()
    }

    const options = panel.locator('[data-apply-existing-tag-target="option"]')
    const count = await options.count()
    if (count <= 8) return

    const more = panel.getByRole('button', { name: 'More' })
    await expect(more).toBeVisible()
    await expect(options.nth(8)).toBeHidden()

    await more.click()
    await expect(more).toBeHidden()
    await expect(options.nth(8)).toBeVisible()
  })
})
